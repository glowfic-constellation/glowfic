redis_connection = Redis.new(url: ENV["REDIS_URL"]) if ENV['REDIS_URL']
namespace = "glowfic:#{Rails.env}"
$redis = Redis::Namespace.new(namespace, :redis => redis_connection)
