# frozen_string_literal: true
class Post::View < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false
  belongs_to :last_read_reply, class_name: 'Reply', optional: true, inverse_of: false

  validates :post, uniqueness: { scope: :user }

  after_create :mark_favorite_read

  # the marker's live position within the post; NULL if the marker is unset or its reply is gone
  scope :with_last_read_reply_order, -> {
    left_joins(:last_read_reply).select('replies.reply_order AS last_read_reply_order')
  }

  private

  def mark_favorite_read
    favorited_continuity = user.favorites.where(favorite: post.board).exists?
    favorited_users = user.favorites.where(favorite: post.joined_authors).exists?
    return unless favorited_continuity || favorited_users

    message = NotifyFollowersOfNewPostJob.notification_about(post, user, unread_only: true)
    return unless message

    message.update!(unread: false, read_at: Time.zone.now)
  end
end
