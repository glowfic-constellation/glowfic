require 'resque/server'

Resque.before_fork do
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
end

Resque.after_fork do
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end

Resque::Mailer.error_handler = lambda { |mailer, message, error, action, args|
  # Necessary to re-enqueue jobs that receieve the SIGTERM signal
  if error.is_a?(Resque::TermException)
    Resque.enqueue(mailer, action, *args)
  else
    raise error
  end
}
Resque::Mailer.excluded_environments = [] # I explicitly want this to run in tests; don't exclude them.

if Rails.env.production?
  Resque::Server.use(Rack::Auth::Basic) do |user, password|
    username = ENV['RESQUE_WEB_HTTP_BASIC_AUTH_USER'] || 'user'
    pw = ENV['RESQUE_WEB_HTTP_BASIC_AUTH_PASSWORD'] || 'secret'
    [user, password] == [username, pw]
  end
end

# only logs Resque failures when they are not retried
# require 'resque/failure/redis'
# Resque::Failure::MultipleWithRetrySuppression.classes = [Resque::Failure::Redis]
# Resque::Failure.backend = Resque::Failure::MultipleWithRetrySuppression
