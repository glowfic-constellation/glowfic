# frozen_string_literal: true
redis_connection = Redis.new(url: ENV["REDIS_URL"], ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) if ENV['REDIS_URL']
namespace = "glowfic:#{Rails.env}"
$redis = Redis::Namespace.new(namespace, redis: redis_connection)
Resque.redis = $redis
