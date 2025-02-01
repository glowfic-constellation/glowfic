# frozen_string_literal: true
require 'resque/server'

Resque.before_fork do
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
end

Resque.after_fork do
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end

if Rails.env.production?
  Resque::Server.use(Rack::Auth::Basic) do |user, password|
    username = ENV.fetch('RESQUE_WEB_HTTP_BASIC_AUTH_USER', 'user')
    pw = ENV.fetch('RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD', 'secret')
    [user, password] == [username, pw]
  end
end

# only logs Resque failures when they are not retried
# require 'resque/failure/redis'
# Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
# Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression

# logs Resque failures and sends them to ExceptionNotification
require 'resque/failure/multiple'
require 'resque/failure/redis'
require 'exception_notification/resque'

Resque::Failure::Multiple.classes = [Resque::Failure::Redis, ExceptionNotification::Resque]
Resque::Failure.backend = Resque::Failure::Multiple
