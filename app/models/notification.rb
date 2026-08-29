# frozen_string_literal: true
class Notification < ApplicationRecord
  belongs_to :user, inverse_of: :notifications, optional: false
  belongs_to :post, inverse_of: :notifications, optional: true

  before_create :check_read
  after_create_commit :notify_recipient

  scope :unread, -> { where(unread: true) }
  scope :ordered, -> { order(created_at: :desc) }

  scope :visible_to, ->(user) {
    left_outer_joins(:post)
      .merge(Post.visible_to(user))
      .where.not(post_id: user.hidden_posts)
      .or(left_outer_joins(:post).where(post_id: nil))
  }

  scope :not_ignored_by, ->(user) {
    left_outer_joins(:post)
      .merge(Post.not_ignored_by(user))
      .or(left_outer_joins(:post).where(post_id: nil))
  }

  enum :notification_type, {
    import_success: 0,
    import_fail: 1,
    new_favorite_post: 2,
    joined_favorite_post: 3,
    wrangling_scope_merged: 4,
    tag_suggested: 5,
  }

  attr_accessor :skip_email

  def self.notify_user(user, type, post: nil, error: nil)
    Notification.create!(user: user, notification_type: type, post: post, error_msg: error)
  end

  # Only meaningful for notifications about a post's own content: having read
  # the post says nothing about whether you have seen a tag suggested on it.
  PRE_READ_EXEMPT_TYPES = ['tag_suggested'].freeze

  private

  def check_read
    return unless post
    return if PRE_READ_EXEMPT_TYPES.include?(notification_type)
    view = Post::View.find_by(user: user, post: post)
    return unless view&.read_at
    self.read_at = view.read_at
    self.unread = false
  end

  def notify_recipient
    return if skip_email
    return unless user.email.present?
    return unless user.email_notifications?
    UserMailer.new_notification(self.id).deliver_later
  end
end
