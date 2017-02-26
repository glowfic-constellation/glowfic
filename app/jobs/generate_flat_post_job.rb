class GenerateFlatPostJob < BaseJob
  @queue = :high
  @retry_limit = 5
  @expire_retry_key_after = 3600

  def self.process(post_id)
    Rails.logger.info("[GenerateFlatPostJob] updating flat post for post #{post_id}")
    return unless post = Post.find_by_id(post_id)

    lock_key = self.lock_key(post_id)

    begin
      replies = post.replies
        .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username')
        .joins(:user)
        .joins("LEFT OUTER JOIN characters ON characters.id = replies.character_id")
        .joins("LEFT OUTER JOIN icons ON icons.id = replies.icon_id")
        .order('id asc')

      view = ActionView::Base.new(ActionController::Base.view_paths, {})
      view.extend ApplicationHelper
      content = view.render(partial: 'posts/generate_flat', locals: {replies: replies})

      flat_post = post.flat_post
      flat_post.content = content
      flat_post.save

      $redis.del(lock_key)
    rescue Exception => e
      $redis.del(lock_key)
      raise e # jobs are automatically retried
    end
  end

  def self.lock_key(post_id)
    "lock.generate_flat_posts.#{post_id}"
  end

  def self.notify_exception(exception, *args)
    $redis.del(self.lock_key(args[0]))
    super
  end
end
