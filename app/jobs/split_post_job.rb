# frozen_string_literal: true
class SplitPostJob < ApplicationJob
  queue_as :low

  REPLY_ATTRS = [:character_id, :icon_id, :character_alias_id, :user_id, :content, :created_at, :updated_at, :editor_mode].map(&:to_s)
  POST_ATTRS = [:board_id, :section_id, :privacy, :status, :authors_locked].map(&:to_s)
  POST_ASSOCS = [:setting_ids, :label_ids, :content_warning_ids].map(&:to_s) # Associations aren't attributes so they're handled separately

  def perform(reply_id, new_subject)
    raise RuntimeError, "Invalid subject" if new_subject.blank?
    Post.transaction do
      first_reply = Reply.find_by(id: reply_id)
      raise RuntimeError, "Couldn't find reply" unless first_reply
      old_post = first_reply.post

      other_replies = old_post.replies.where('reply_order > ?', first_reply.reply_order).ordered
      new_post = create_post(first_reply, old_post: old_post, subject: new_subject)

      new_authors = find_authors(other_replies)
      migrate_replies(other_replies, new_post: new_post, old_post: old_post, first_reply: first_reply)
      cleanup_first(first_reply)
      update_authors(new_authors, new_post: new_post, old_post: old_post)
      update_caches(new_post, new_post.replies.ordered.last)
      update_caches(old_post, old_post.replies.ordered.last)
    end
  end

  private

  def create_post(first_reply, old_post:, subject:)
    new_post = Post.new(first_reply.attributes.slice(*REPLY_ATTRS))
    new_post.skip_edited = true
    new_post.is_import = true
    new_post.assign_attributes(old_post.attributes.slice(*POST_ATTRS))
    POST_ASSOCS.each do |assoc|
      new_post.send(assoc + "=", old_post.send(assoc))
    end
    new_post.subject = subject
    new_post.edited_at = first_reply.updated_at
    new_post.save!
    new_post
  end

  def find_authors(other_replies)
    # collect user ids for the new post's replies and created_at of first replies of that set for the author
    author_ids = other_replies.except(:order).select(:user_id).distinct.pluck(:user_id)
    author_ids.index_with { |id| other_replies.find_by(user_id: id).created_at }
  end

  def migrate_replies(other_replies, new_post:, old_post:, first_reply:)
    count = other_replies.count
    return {} if count.zero?

    sql = <<~SQL.squish
      WITH v_replies AS
      (
        SELECT ROW_NUMBER() OVER(ORDER BY replies.reply_order asc) AS rn, id
        FROM replies
        WHERE replies.post_id = :old_id AND reply_order > :reply_num
      )
      UPDATE replies
      SET reply_order = v_replies.rn-1, post_id = :new_id
      FROM v_replies
      WHERE replies.id = v_replies.id;
    SQL
    sql = ActiveRecord::Base.sanitize_sql_array([sql, old_id: old_post.id, reply_num: first_reply.reply_order, new_id: new_post.id])
    ActiveRecord::Base.connection.execute(sql)
  end

  def cleanup_first(first_reply)
    first_reply.delete
    raise ActiveRecord::RecordNotDestroyed if Reply.exists?(first_reply.id)
  end

  def update_authors(new_authors, new_post:, old_post:)
    new_authors.each do |user_id, timestamp|
      user = User.find_by(id: user_id)
      next unless new_post.author_for(user).nil?
      existing = old_post.author_for(user)
      data = {
        user_id: user_id,
        created_at: timestamp,
        updated_at: [existing.updated_at, timestamp].max,
        joined_at: timestamp,
      }
      data.merge!(existing.attributes.slice([:can_owe, :can_reply, :joined]))
      new_post.post_authors.create!(data)
    end
    still_valid = (old_post.replies.distinct.pluck(:user_id) + [old_post.user_id]).uniq
    invalid = old_post.post_authors.where.not(user_id: still_valid)
    invalid.destroy_all
  end

  def update_caches(post, last_reply)
    if last_reply.nil?
      cached_data = {
        last_reply_id: nil,
        last_user_id: post.user_id,
        tagged_at: post.edited_at,
      }
    else
      cached_data = {
        last_reply_id: last_reply.id,
        last_user_id: last_reply.user_id,
        tagged_at: last_reply.updated_at,
      }
    end

    post.update_columns(cached_data) # rubocop:disable Rails/SkipsModelValidations
  end
end
