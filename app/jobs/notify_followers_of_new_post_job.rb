class NotifyFollowersOfNewPostJob < ApplicationJob
  queue_as :notifier

  def perform(post_id, user_id)
    return unless (post = Post.find_by_id(post_id))
    return unless (user = User.find_by_id(user_id))

    if post.user_id == user_id
      notify_of_post_creation(post, user)
    else
      notify_of_post_joining(post, user)
    end
  end

  def notify_of_post_creation(post, new_user)
    users_favoriting_user = Favorite.where(favorite: new_user).pluck(:user_id)
    users_favoriting_continuity = Favorite.where(favorite: post.board).pluck(:user_id)
    user_ids = (users_favoriting_continuity + users_favoriting_user).uniq - [post.user_id]
    return unless user_ids.present?
    users = User.where(id: user_ids)

    users.each do |user|
      next unless user.favorite_notifications?
      next unless post.visible_to?(user)
      message = "#{new_user.username} has just posted a new post entitled #{post.subject}"
      message += " in the #{post.board.name} continuity" if users_favoriting_continuity.include?(user.id)
      message += " with " + (post.authors - [new_user]).map(&:username).join(", ")
      message += ". #{view_post(post.id)}"
      Message.send_site_message(user.id, 'New post by ' + post.user.username, message)
    end
  end

  def notify_of_post_joining(post, new_user)
    user_ids = Favorite.where(favorite: new_user).pluck(:user_id) - [post.user_id]
    return unless user_ids.present?
    users = User.where(id: user_ids)

    subject = new_user.username + ' has joined a new thread'

    users.each do |user|
      next unless user.favorite_notifications?
      next unless post.visible_to?(user)
      next if already_notified_about?(post, user)
      message = "#{new_user.username} has just joined the post entitled #{post.subject} with "
      message += (post.joined_authors - [new_user]).map(&:username).join(", ")
      message += ". #{view_post(post.id)}"
      Message.send_site_message(user.id, subject, message)
    end
  end

  def already_notified_about?(post, user)
    Message.where(recipient: user, sender_id: 0).find_each do |notification|
      return true if notification.message.include?(view_post(post.id))
    end
    false
  end

  def view_post(post_id)
    url = Rails.application.routes.url_helpers.post_url(post_id, host: ENV['DOMAIN_NAME'] || 'localhost:3000', protocol: 'https')
    "<a href='#{url}'>View it here</a>."
  end
end
