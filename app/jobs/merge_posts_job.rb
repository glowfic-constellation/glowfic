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
      add_author_viewers(target_post) if target_post.privacy_access_list?
      update_caches(source_post, target_post)
      send_notifications(source_post, target_post, target_reply, recipients)
      migrate_post_references(source_post, target_post)
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
    User.where(id: recipients[:target_opener_ids]).find_each do |user|
      # the merged privacy may have hidden the post, making its notifications invisible too
      next unless target_post.visible_to?(user)
      Notification.create!(user: user, notification_type: :target_post_merged, post: target_post,
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
    marker_ids = (source_states.values + target_states.values).filter_map { |state| state[:view].last_read_reply_id }
    marker_orders = Reply.where(id: marker_ids.uniq).pluck(:id, :reply_order).to_h

    rewound_view_ids = []
    target_states.each do |user_id, target|
      source = source_states[user_id]
      view = target[:view]

      # a view without a read_at (e.g. from hiding the post unread) is not an opened post;
      # users who never opened the source shouldn't have its replies spliced in unseen behind
      # their marker, so it rewinds to the insertion point and they count as unread
      if source.nil? || source[:view].read_at.blank?
        marker_order = marker_orders[view.last_read_reply_id]
        rewound_view_ids << view.id if marker_order && marker_order > target_reply.reply_order
        next
      end

      marker_id = merged_marker_id(source, target, marker_orders)
      read_at = merged_read_at(source, target)
      next if marker_id == view.last_read_reply_id && read_at == view.read_at
      view.update!(last_read_reply_id: marker_id, read_at: read_at)
    end

    return if rewound_view_ids.empty?
    Post::View.where(id: rewound_view_ids).update_all(last_read_reply_id: target_reply.id) # rubocop:disable Rails/SkipsModelValidations
  end

  def merged_marker_id(source, target, marker_orders)
    source_id = source[:view].last_read_reply_id
    target_id = target[:view].last_read_reply_id
    return target_id if source_id.nil? || target_id.nil?

    # both markers now live in the target post, so their orders compare directly;
    # markers whose replies are gone have no order and cannot win
    candidates = [source_id, target_id].filter_map { |id| [id, marker_orders[id]] if marker_orders[id] }
    return target_id if candidates.empty?

    if source[:caught_up] && target[:caught_up]
      candidates.max_by(&:second).first
    elsif source[:caught_up]
      target_id
    elsif target[:caught_up]
      source_id
    else
      candidates.min_by(&:second).first
    end
  end

  def merged_read_at(source, target)
    read_ats = [source[:view].read_at, target[:view].read_at].compact
    return if read_ats.empty?
    source[:caught_up] && target[:caught_up] ? read_ats.max : read_ats.min
  end

  def merge_authors(source_post, target_post)
    target_authors = target_post.post_authors.index_by(&:user_id)
    source_post.post_authors.each do |source_author|
      target_author = target_authors[source_author.user_id]
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
    target_drafts = ReplyDraft.where(post_id: target_post.id).index_by(&:user_id)
    ReplyDraft.where(post_id: source_post.id).find_each do |draft|
      target_draft = target_drafts[draft.user_id]
      if target_draft.nil?
        draft.update!(post_id: target_post.id)
        next
      end

      note = draft_note(draft, source_post)
      if (target_author = target_post.author_for(draft.user))
        target_author.update!(private_note: merged_note(note, target_author.private_note))
      else
        # non-authors have no author notes, and creating an author row would grant them
        # authorship; preserve the displaced draft in their surviving draft instead
        target_draft.update!(content: merged_note(note, target_draft.content))
      end
      draft.destroy!
    end
  end

  # preserves a draft displaced by the user's existing draft in the target post
  def draft_note(draft, source_post)
    note = "<strong>Unposted draft from \"#{ERB::Util.html_escape(source_post.subject)}\":</strong>\n"
    if (character = draft.character)
      note += ERB::Util.html_escape(character.npc? ? "#{character.name} (NPC)" : character.name)
      note += " | #{ERB::Util.html_escape(character.screenname)}" if character.screenname.present?
      note += " | icon: #{ERB::Util.html_escape(draft.icon.keyword)}" if draft.icon
    elsif draft.icon
      note += "icon: #{ERB::Util.html_escape(draft.icon.keyword)}"
    end
    "#{note}\n<br>\n#{draft.content}"
  end

  # followers, curated indexes, and old notifications keep tracking the merged post;
  # duplicates are left behind to be destroyed along with the source post
  def migrate_post_references(source_post, target_post)
    existing_favoriters = Favorite.where(favorite: target_post).pluck(:user_id)
    Favorite.where(favorite: source_post).where.not(user_id: existing_favoriters).update_all(favorite_id: target_post.id)

    existing_index_ids = IndexPost.where(post_id: target_post.id).pluck(:index_id)
    IndexPost.where(post_id: source_post.id).where.not(index_id: existing_index_ids).update_all(post_id: target_post.id)

    Notification.where(post_id: source_post.id).update_all(post_id: target_post.id)
  end

  # an access list would otherwise hide the post from authors who aren't already on it
  def add_author_viewers(target_post)
    missing = target_post.post_authors.pluck(:user_id) - target_post.post_viewers.pluck(:user_id) - [target_post.user_id]
    missing.each { |user_id| target_post.post_viewers.create!(user_id: user_id) }
  end

  def update_caches(source_post, target_post)
    last_reply = target_post.replies.ordered.last
    cached_data = {
      last_reply_id: last_reply.id,
      last_user_id: last_reply.user_id,
      tagged_at: [source_post.tagged_at, target_post.tagged_at].max,
    }
    # merged-in replies end an author-set hiatus, like posting a reply would
    cached_data[:status] = Post.statuses[:active] if target_post.hiatus?
    target_post.update_columns(cached_data)
  end
  # rubocop:enable Rails/SkipsModelValidations
end
