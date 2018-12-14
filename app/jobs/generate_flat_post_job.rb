class GenerateFlatPostJob < ApplicationJob
  queue_as :high

  def self.enqueue(post_id, reply_id: nil)
    # frequent tag check
    lock_key = lock_key(post_id)
    return if $redis.get(lock_key)
    $redis.set(lock_key, true)

    perform_later(post_id, reply_id)
  end

  def perform(post_id, reply_id: nil)
    Rails.logger.info("[GenerateFlatPostJob] updating flat post for post #{post_id}")
    return unless (post = Post.find_by_id(post_id))

    lock_key = self.class.lock_key(post_id)

    begin
      PostFlatten.new(post_id, reply_id: reply_id).update
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
