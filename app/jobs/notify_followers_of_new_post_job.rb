class NotifyFollowersOfNewPostJob < BaseJob
  @queue = :high
  @retry_limit = 5
  @expire_retry_key_after = 3600

  def self.process(post_id)
    return unless post = Post.find_by_id(post_id)

    users_favoriting_user = Favorite.where(favorite: post.user).pluck(:user_id)
    users_favoriting_continuity = Favorite.where(favorite: post.board).pluck(:user_id)
    user_ids = (users_favoriting_continuity + users_favoriting_user).uniq - [post.user_id]
    return unless user_ids.present?
    users = User.where(id: user_ids)

    subject = 'New post by ' + post.user.username
    users.each do |user|
      next unless post.visible_to?(user)
      message = "#{post.user.username} has just posted a new post entitled #{post.subject}"
      message += " in the #{post.board.name} continuity" if users_favoriting_continuity.include?(user.id)
      message += ". #{view_post(post_id)}"
      Message.send_site_message(user.id, subject, message)
    end
  end

  def self.view_post(post_id)
    url = Rails.application.routes.url_helpers.post_url(post_id, host: ENV['DOMAIN_NAME'] || 'localhost:3000', protocol: 'https')
    "<a href='#{url}'>View it here</a>."
  end
end
