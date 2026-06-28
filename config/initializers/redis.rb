# frozen_string_literal: true
redis_connection = Redis.new(url: ENV["REDIS_URL"], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) if ENV['REDIS_URL']
namespace = "glowfic:#{Rails.env}"
# parallel_tests workers share one Redis server; give each its own namespace so
# their keys (job locks, caches, rate-limit buckets) don't collide cross-worker.
namespace += ":w#{ENV['TEST_ENV_NUMBER'].presence || '1'}" if Rails.env.test? && ENV.key?('TEST_ENV_NUMBER')
$redis = Redis::Namespace.new(namespace, redis: redis_connection)
Resque.redis = $redis
