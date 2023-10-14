redis_connection = Redis.new(url: ENV["REDIS_URL"]) if ENV['REDIS_URL']
namespace = "glowfic:#{Rails.env}"
namespace += ":#{ENV['TEST_ENV_NUMBER']}" if Rails.env.test?
$redis = Redis::Namespace.new(namespace, redis: redis_connection)
Resque.redis = $redis
