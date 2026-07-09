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
      merge_replies(source_post, target_post, target_reply)
      merge_authors(source_post, target_post)
      merge_drafts(source_post, target_post)
      target_post.update!(privacy: privacy, setting_ids: setting_ids, content_warning_ids: content_warning_ids, label_ids: label_ids)
      update_caches(source_post, target_post)
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
