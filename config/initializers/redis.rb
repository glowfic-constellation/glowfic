$redis = Redis.new(url: ENV["REDIS_URL"]) if ENV['REDIS_URL']
