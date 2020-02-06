class GenerateFlatPostJob < ApplicationJob
  queue_as :high

  EXPIRY_SECONDS = 30 * 60
  REPLIES_PER_RECORD = 500

  def self.enqueue(post_id)
    # frequent tag check
    lock_key = lock_key(post_id)
    # set lock iff not already locked, with expiry to prevent infinite broken locks
    locked = $redis.set(lock_key, true, ex: EXPIRY_SECONDS, nx: true)
    return unless locked

    perform_later(post_id)
  end

  def perform(post_id)
    Rails.logger.info("[GenerateFlatPostJob] updating flat post for post #{post_id}")
    return unless (post = Post.find_by_id(post_id))

    lock_key = self.class.lock_key(post_id)

    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    view.extend ApplicationHelper

    begin
      post.replies.ordered.in_batches(batch_size: REPLIES_PER_RECORD) do |replies, batch_num|
        flat_post = post.flat_posts[batch_num]
        next if replies.maximum(:updated_at) < flat_post.updated_at

        replies = replies
          .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username')
          .joins(:user)
          .left_outer_joins(:character)
          .left_outer_joins(:icon)
          .ordered

        content = view.render(partial: 'posts/generate_flat', locals: {replies: replies})

        flat_post.content = content
        flat_post.save!
      end

      $redis.del(lock_key)
    rescue StandardError => e
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
