Flatware.configure do |conf|
  conf.before_fork do
    require 'rails_helper'

    ActiveRecord::Base.connection.disconnect!
  end

  conf.after_fork do |test_env_number|
    require 'simplecov'
    # allow SimpleCov to combine parallel results
    SimpleCov.at_fork.call(test_env_number)

    # re-establish ActiveRecord connection
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    ActiveRecord::Base.establish_connection(
      config.merge(
        database: config.fetch(:database) + test_env_number.to_s,
      ),
    )

    # re-establish Redis connections (automatic cache, global variable, Resque)
    store_name, store_configs = Rails.application.config.cache_store
    Rails.cache = ActiveSupport::Cache.lookup_store(
      store_name,
      store_configs.merge(namespace: test_env_number),
    )
    namespace = "glowfic:#{Rails.env}:#{test_env_number}"
    $redis = Redis::Namespace.new(namespace, redis: $redis.redis)
    Resque.redis = $redis
  end
end
