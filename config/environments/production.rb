require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser
  # config.assets.css_compressor = :sass

  # Do not fall back to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = {
    'cache-control' => "public, max-age=#{1.year.to_i}",
  }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.action_controller.asset_host = ENV.fetch('ASSET_HOST', nil) # staging doesn't have a CDN, so this needs to default to nil

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true
  config.ssl_options = { hsts: { preload: true } }

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "warn").to_sym

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :redis_cache_store,
                       { url: ENV.fetch('REDIS_CACHE_URL'), expires_in: 30.days, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "glowfic_production"

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  # config.action_mailer.default_url_options = { host: "example.com" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  config.action_mailer.delivery_method = :ses
  config.action_mailer.ses_settings = { region: 'us-east-1' }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  # use ExceptionNotification to email Marri stack traces
  Rails.application.config.middleware.use ExceptionNotification::Rack,
    ignore_exceptions: [
      'Rack::Timeout::RequestTimeoutException',
      'ActiveRecord::QueryCanceled',
      'ActionDispatch::Http::MimeNegotiation::InvalidType',
    ] + ExceptionNotifier.ignored_exceptions,
    email: {
      email_prefix: "[Glowfic Constellation Error] ",
      sender_address: %{"Glowfic Constellation" <glowfic.constellation@gmail.com>},
      exception_recipients: %w{glowfic.constellation@gmail.com},
    }
end
