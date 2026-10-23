# frozen_string_literal: true

require 'securerandom'

# Profiles PROFILE_SAMPLE_RATE of requests (0 = off) with Vernier and uploads them
# to profiles/<date>/ in the public icon bucket, so they hold no user data. The
# transaction gets a profile_key attribute. One profile at a time per process.
class ProfileSampler
  MAX_RATE = 0.05

  INTERVAL_MICROSECONDS = 1000

  # Profiles beyond this are dropped.
  QUEUE_SIZE = 4

  def self.rate
    ENV['PROFILE_SAMPLE_RATE'].to_f.clamp(0.0, MAX_RATE)
  end

  def initialize(app, rate: self.class.rate, uploader: method(:upload))
    @app = app
    @rate = rate
    @uploader = uploader
    @lock = Mutex.new
  end

  def call(env)
    return @app.call(env) unless @rate.positive? && rand < @rate
    return @app.call(env) unless @lock.try_lock

    begin
      profile(env)
    ensure
      @lock.unlock
    end
  end

  private

  def profile(env)
    response = nil
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = Vernier.profile(interval: INTERVAL_MICROSECONDS, hooks: [:rails]) do
      response = @app.call(env)
    end
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    enqueue(env, result, response.first, elapsed)
    response
  end

  def enqueue(env, result, status, elapsed)
    key = object_key(env, status, elapsed)
    NewRelic::Agent.add_custom_attributes(profile_key: key) if defined?(NewRelic::Agent)
    uploads.push([key, result], true)
  rescue ThreadError
    Rails.logger.info("[profile_sampler] upload queue full, dropped #{key}")
  rescue StandardError => e
    Rails.logger.warn("[profile_sampler] #{e.class}: #{e.message}")
  end

  def object_key(env, status, elapsed)
    params = env['action_dispatch.request.path_parameters'] || {}
    action = [params[:controller], params[:action]].compact.join('#').presence || 'unrouted'
    now = Time.now.utc
    [
      'profiles',
      now.strftime('%Y-%m-%d'),
      "#{now.strftime('%H%M%S')}-#{action.tr('/#', '--')}-#{status}-#{(elapsed * 1000).round}ms-#{SecureRandom.hex(8)}.json.gz",
    ].join('/')
  end

  # A thread does not survive Puma's fork, so each worker starts its own.
  def uploads
    return @uploads if @uploads_pid == Process.pid
    @uploads_pid = Process.pid
    @uploads = SizedQueue.new(QUEUE_SIZE)
    queue = @uploads
    Thread.new do
      loop do
        key, result = queue.pop
        @uploader.call(key, result)
      rescue StandardError => e
        Rails.logger.warn("[profile_sampler] upload of #{key} failed: #{e.class}: #{e.message}")
      end
    end
    @uploads
  end

  def upload(key, result)
    S3_BUCKET.put_object(
      key: key,
      body: result.to_firefox(gzip: true),
      content_type: 'application/json',
      content_encoding: 'gzip',
    )
  end
end
