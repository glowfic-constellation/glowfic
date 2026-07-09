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
