# frozen_string_literal: true
class GenerateFlatPostJob < ApplicationJob
  queue_as :high

  EXPIRY_SECONDS = 30 * 60
  REPLIES_PER_RENDER_BATCH = 250
  S3_PART_SIZE = 5 * 1024 * 1024
  S3_KEY_PREFIX = 'flat_posts'

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
    return unless (post = Post.find_by(id: post_id))

    lock_key = self.class.lock_key(post_id)

    begin
      replies = post.replies
        .select('replies.*, characters.name, characters.screenname, icons.keyword, icons.url, users.username')
        .joins(:user)
        .left_outer_joins(:character)
        .left_outer_joins(:icon)
        .ordered

      flat_post = post.flat_post || post.build_flat_post

      if post.privacy_public?
        regenerate_to_s3(flat_post, replies)
      else
        regenerate_to_db(flat_post, replies)
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

  def self.s3_key_for(post_id)
    "#{S3_KEY_PREFIX}/#{post_id}.html"
  end

  private

  # Public posts stream the rendered HTML directly into S3 via a multipart
  # upload, so the job's peak memory is bounded by a single batch of replies
  # plus one upload part (~5 MiB) regardless of total reply count.
  def regenerate_to_s3(flat_post, replies)
    key = self.class.s3_key_for(flat_post.post_id)
    S3_BUCKET.object(key).upload_stream(
      content_type: 'text/html; charset=utf-8',
      tempfile: false,
      thread_count: 1,
      part_size: S3_PART_SIZE,
    ) do |stream|
      each_render_batch(replies) { |chunk| stream.write(chunk) }
    end
    flat_post.assign_attributes(s3_key: key, content: nil)
    flat_post.save!
  end

  # Non-public posts stay on the legacy Postgres path so their content does
  # not land in the publicly-readable S3 bucket. The streamed rendering keeps
  # SQL load bounded per batch even though the output buffer still grows
  # linearly here.
  def regenerate_to_db(flat_post, replies)
    body = +''
    each_render_batch(replies) { |chunk| body << chunk }
    flat_post.assign_attributes(content: body, s3_key: nil)
    flat_post.save!
  end

  def each_render_batch(replies)
    page_count = (replies.count(:all) / REPLIES_PER_RENDER_BATCH.to_f).ceil
    1.upto(page_count) do |page|
      yield PostsController.render(
        :_generate_flat,
        layout: false,
        locals: { replies: replies.paginate(per_page: REPLIES_PER_RENDER_BATCH, page: page) },
      )
    end
  end
end
