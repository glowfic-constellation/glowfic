# frozen_string_literal: true
class MergePostsJob < ApplicationJob
  queue_as :low

  def perform(source_post_id, target_reply_id, privacy, setting_ids, content_warning_ids, label_ids)
    source_post = Post.find_by(id: source_post_id)
    raise RuntimeError, "Couldn't find source post" unless source_post

    target_reply = Reply.find_by(id: target_reply_id)
    raise RuntimeError, "Couldn't find target reply" unless target_reply

    target_post = target_reply.post
    Post.transaction do
      source_view_states = view_states(source_post)
      target_view_states = view_states(target_post)
      recipients = notification_recipients(source_post, target_post, source_view_states, target_view_states, target_reply)

      merge_replies(source_post, target_post, target_reply)
      merge_view_markers(source_view_states, target_view_states, target_reply)
      merge_authors(source_post, target_post)
      merge_drafts(source_post, target_post)
      target_post.update!(privacy: privacy, setting_ids: setting_ids, content_warning_ids: content_warning_ids, label_ids: label_ids)
      update_caches(source_post, target_post)
      send_notifications(source_post, target_post, target_reply, recipients)
      source_post.destroy!
    end
    GenerateFlatPostJob.enqueue(target_post.id)
  end

  private

  # rubocop:disable Rails/SkipsModelValidations
  def merge_replies(source_post, target_post, target_reply)
    moved_count = source_post.reply_count # includes the written
    offset = target_reply.reply_order + 1

    following_replies = Reply.where(post_id: target_post.id).where('reply_order > ?', target_reply.reply_order)
    following_replies.update_all(['reply_order = reply_order + ?', moved_count])
    Reply.where(post_id: source_post.id).update_all(['post_id = ?, reply_order = reply_order + ?', target_post.id, offset])
    Bookmark.where(post_id: source_post.id).update_all(post_id: target_post.id)
  end

  # captured pre-merge: authors of either post, non-author users who had opened the source,
  # and non-author users who had opened the target with their marker past the insertion point
  def notification_recipients(source_post, target_post, source_states, target_states, target_reply)
    author_ids = source_post.author_ids | target_post.author_ids
    opened_source = source_states.select { |_, state| state[:view].read_at.present? }.keys

    marker_ids = target_states.values.filter_map { |state| state[:view].last_read_reply_id }
    marker_orders = Reply.where(id: marker_ids).pluck(:id, :reply_order).to_h
    past_insertion = target_states.select do |_, state|
      view = state[:view]
      view.read_at.present? && marker_orders.fetch(view.last_read_reply_id, 0) > target_reply.reply_order
    end.keys

    {
      author_ids: author_ids,
      source_opener_ids: opened_source - author_ids,
      target_opener_ids: past_insertion - author_ids - opened_source,
    }
  end

  def send_notifications(source_post, target_post, target_reply, recipients)
    target_post.reload # author and privacy changes affect the visibility checks below
    message = merge_message(source_post, target_post, target_reply)

    recipients[:author_ids].each do |user_id|
      Notification.create!(user_id: user_id, notification_type: :post_merged_author, post: target_post,
        message: message, skip_check_read: true,)
    end
    User.where(id: recipients[:source_opener_ids]).find_each do |user|
      next unless target_post.visible_to?(user)
      Notification.create!(user: user, notification_type: :source_post_merged, post: target_post,
        message: message, skip_check_read: true,)
    end
    recipients[:target_opener_ids].each do |user_id|
      Notification.create!(user_id: user_id, notification_type: :target_post_merged, post: target_post,
        message: message, skip_check_read: true,)
    end
  end

  def merge_message(source_post, target_post, target_reply)
    path = Rails.application.routes.url_helpers.reply_path(target_reply)
    "Post \"#{ERB::Util.html_escape(source_post.subject)}\" has been merged into " \
      "\"#{ERB::Util.html_escape(target_post.subject)}\" immediately after <a href=\"#{path}\">this reply</a>."
  end

  # pre-merge read state: per user, their view and whether they had read the whole post
  def view_states(post)
    last_reply_id = post.replies.ordered.last.id
    post.views.index_by(&:user_id).transform_values do |view|
      { view: view, caught_up: view.last_read_reply_id == last_reply_id }
    end
  end

  # users who had opened the source but not the target keep no read state; for users who had
  # opened both, the target view's marker and read_at merge based on how caught up they were
  def merge_view_markers(source_states, target_states, target_reply)
    target_states.each do |user_id, target|
      source = source_states[user_id]
      if source.nil?
        rewind_marker_to_insertion(target[:view], target_reply)
        next
      end

      target[:view].update!(
        last_read_reply_id: merged_marker_id(source, target),
        read_at: merged_read_at(source, target),
      )
    end
  end

  # users who never opened the source shouldn't have its replies spliced in unseen behind
  # their marker, so it rewinds to the insertion point and they count as unread
  def rewind_marker_to_insertion(view, target_reply)
    return if view.last_read_reply_id.nil?
    marker_order = Reply.where(id: view.last_read_reply_id).pick(:reply_order)
    return unless marker_order && marker_order > target_reply.reply_order
    view.update!(last_read_reply_id: target_reply.id)
  end

  def merged_marker_id(source, target)
    source_id = source[:view].last_read_reply_id
    target_id = target[:view].last_read_reply_id
    return target_id if source_id.nil? || target_id.nil?

    # both markers now live in the target post, so their orders compare directly
    if source[:caught_up] && target[:caught_up]
      marker_by_order(source_id, target_id, :max_by)
    elsif source[:caught_up]
      target_id
    elsif target[:caught_up]
      source_id
    else
      marker_by_order(source_id, target_id, :min_by)
    end
  end

  def marker_by_order(source_id, target_id, comparison)
    Reply.where(id: [source_id, target_id]).pluck(:id, :reply_order).send(comparison, &:second).first
  end

  def merged_read_at(source, target)
    read_ats = [source[:view].read_at, target[:view].read_at].compact
    return if read_ats.empty?
    source[:caught_up] && target[:caught_up] ? read_ats.max : read_ats.min
  end

  def merge_authors(source_post, target_post)
    source_post.post_authors.each do |source_author|
      target_author = target_post.author_for(source_author.user)
      if target_author.nil?
        target_post.post_authors.create!(source_author.attributes.except('id', 'post_id'))
      else
        target_author.update!(
          private_note: merged_note(target_author.private_note, source_author.private_note),
          joined: target_author.joined || source_author.joined,
          joined_at: [target_author.joined_at, source_author.joined_at].compact.min,
          can_reply: target_author.can_reply || source_author.can_reply,
        )
      end
    end
  end

  def merged_note(target_note, source_note)
    return source_note if target_note.blank?
    return target_note if source_note.blank?
    "#{target_note}\n\n<hr>\n\n#{source_note}"
  end

  def merge_drafts(source_post, target_post)
    ReplyDraft.where(post_id: source_post.id).find_each do |draft|
      if ReplyDraft.where(post_id: target_post.id, user_id: draft.user_id).exists?
        target_author = target_post.author_for(draft.user) || target_post.post_authors.create!(user_id: draft.user_id)
        target_author.update!(private_note: merged_note(draft_note(draft, source_post), target_author.private_note))
        draft.destroy!
      else
        draft.update!(post_id: target_post.id)
      end
    end
  end

  # preserves a draft displaced by the user's existing draft in the target post
  def draft_note(draft, source_post)
    note = "<strong>Unposted draft from \"#{source_post.subject}\":</strong>\n"
    if (character = draft.character)
      note += character.npc? ? "#{character.name} (NPC)" : character.name
      note += " | #{character.screenname}" if character.screenname.present?
      note += " | icon: #{draft.icon.keyword}" if draft.icon
    elsif draft.icon
      note += "icon: #{draft.icon.keyword}"
    end
    "#{note}\n<br>\n#{draft.content}"
  end

  def update_caches(source_post, target_post)
    last_reply = target_post.replies.ordered.last
    target_post.update_columns(
      last_reply_id: last_reply.id,
      last_user_id: last_reply.user_id,
      tagged_at: [source_post.tagged_at, target_post.tagged_at].max,
    )
  end
  # rubocop:enable Rails/SkipsModelValidations
end
