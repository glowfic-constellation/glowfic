# frozen_string_literal: true
class NotifyCoauthorsJob < ApplicationJob
  queue_as :notifier

  def perform(post_id, user_id)
    post = Post.find_by(id: post_id)
    user = User.find_by(id: user_id)
    return unless post && user
    return if post.privacy_private?
    return if post.privacy_access_list? && post.viewers.exclude?(user)

    Notification.notify_user(user, :coauthor_invitation, post: post)
  end
end
