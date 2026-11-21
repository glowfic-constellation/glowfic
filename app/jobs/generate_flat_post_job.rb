# frozen_string_literal: true
class GenerateFlatPostJob < ApplicationJob
  queue_as :high

  EXPIRY_SECONDS = 30 * 60
  RUNNING_EXPIRY_SECONDS = 5 * 60

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

    # Release the "pending" lock before reading the replies, not after saving: a reply saved while this
    # job is rendering finds the lock free and enqueues another run, instead of being skipped by a lock
    # this job is about to delete (which left that reply out of the flat post until the next change).
    $redis.del(self.class.lock_key(post_id))

    # Only one worker may render a given post at a time, or an older render could finish last and
    # overwrite a newer one. If another worker is rendering it, mark the post dirty and leave: that
    # worker re-enqueues a run when it finishes.
    return unless (post = Post.find_by(id: post_id))

    running_key = self.class.running_key(post_id)
    unless $redis.set(running_key, true, ex: RUNNING_EXPIRY_SECONDS, nx: true)
      $redis.set(self.class.dirty_key(post_id), true, ex: EXPIRY_SECONDS)
      return
    end

    begin
      replies = post.replies
        .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username')
        .joins(:user)
        .left_outer_joins(:character)
        .left_outer_joins(:icon)
        .ordered

      flat_post = post.flat_post || post.build_flat_post
      flat_post.content = PostsController.render :_generate_flat, layout: false, locals: { replies: replies }
      flat_post.save!
    ensure
      $redis.del(running_key)
      self.class.perform_later(post_id) if $redis.del(self.class.dirty_key(post_id)).positive?
    end
  end

  def self.lock_key(post_id)
    "lock.generate_flat_posts.#{post_id}"
  end

  def self.running_key(post_id)
    "running.generate_flat_posts.#{post_id}"
  end

  def self.dirty_key(post_id)
    "dirty.generate_flat_posts.#{post_id}"
  end

  def self.notify_exception(exception, *args)
    $redis.del(self.lock_key(args[0]))
    super
  end
end
