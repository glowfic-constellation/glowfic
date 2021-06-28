# frozen_string_literal: true
class NotifyFollowersOfNewPostJob < ApplicationJob
  queue_as :notifier

  ACTIONS = ['new', 'join', 'access', 'public']

  def perform(post_id, user_id, action)
    post = Post.find_by(id: post_id)
    return unless post && ACTIONS.include?(action)
    return if post.privacy_private?

    if ['join', 'access'].include?(action)
      user = User.find_by(id: user_id)
      return unless user
    end

    case action
      when 'new'
        notify_of_post_creation(post)
      when 'join'
        notify_of_post_joining(post, user)
      when 'access'
        notify_of_post_access(post, user)
    end
  end

  def self.notification_about(post, user, unread_only: false)
    previous_types = [:new_favorite_post, :joined_favorite_post, :accessible_favorite_post]
    notif = Notification.find_by(post: post, notification_type: previous_types)
    if notif
      return notif if !unread_only || notif.unread
    else
      messages = Message.where(recipient: user, sender_id: 0).where('created_at >= ?', post.created_at)
      messages = messages.unread if unread_only
      messages.find_each do |notification|
        return notification if notification.message.include?(ScrapePostJob.view_post(post.id))
      end
    end
    nil
  end

  private

  def notify_of_post_creation(post)
    favorites = Favorite.where(favorite: post.authors).or(Favorite.where(favorite: post.board))
    user_ids = favorites.select(:user_id).distinct.pluck(:user_id)
    users = filter_users(post, user_ids)

    return if users.empty?

    users.each { |user| Notification.notify_user(user, :new_favorite_post, post: post) }
  end

  def notify_of_post_joining(post, new_user)
    users = filter_users(post, Favorite.where(favorite: new_user).pluck(:user_id))
    return if users.empty?

    users.each do |user|
      next if already_notified_about?(post, user)
      Notification.notify_user(user, :joined_favorite_post, post: post)
    end
  end

  def notify_of_post_access(post, viewer)
    return unless viewer.favorite_notifications? && post.author_ids.exclude?(viewer.id)
    return if already_notified_about?(post, viewer)
    return unless Favorite.where(favorite: post.authors).or(Favorite.where(favorite: post.board)).where(user: viewer).exists?
    Notification.notify_user(viewer, :accessible_favorite_post, post: post)
  end

  def filter_users(post, user_ids)
    user_ids &= PostViewer.where(post: post).pluck(:user_id) if post.privacy_access_list?
    user_ids -= post.author_ids
    user_ids -= blocked_user_ids(post)
    return [] unless user_ids.present?
    users = User.where(id: user_ids, favorite_notifications: true)
    users = users.full if post.privacy_full_accounts?
    users
  end

  def already_notified_about?(post, user)
    self.class.notification_about(post, user).present?
  end

  def blocked_user_ids(post)
    blocked = Block.where(blocked_user_id: post.author_ids).where("hide_them >= ?", Block.hide_thems[:posts])
    blocked = blocked.select(:blocking_user_id).distinct.pluck(:blocking_user_id)
    blocking = Block.where(blocking_user_id: post.author_ids).where("hide_me >= ?", Block.hide_mes[:posts])
    blocking = blocking.select(:blocked_user_id).distinct.pluck(:blocked_user_id)
    (blocked + blocking).uniq
  end
end
