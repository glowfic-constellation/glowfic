require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.enable_reloading = true

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable server timing
  config.server_timing = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_CACHE_URL', nil) }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}",
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Use a real queuing backend for Active Job (and separate queues per environment)
  config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "glowfic_#{Rails.env}"
  config.action_mailer.perform_caching = false

  # Don't care if the mailer can't send.
  # Swap these lines with the commented lines to send mail.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = false
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.perform_deliveries = true
  # config.action_mailer.raise_delivery_errors = true
  # config.action_mailer.asset_host = "http://localhost:3000"
  # Rails.application.config.middleware.use ExceptionNotification::Rack,
  # :email => {
  #   :email_prefix => "[Glowfic Constellation Error] ",
  #   :sender_address => %{"Glowfic Constellation" <glowfic.constellation@gmail.com>},
  #   :exception_recipients => %w{glowfic.constellation@gmail.com}
  # }

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Highlight code that enqueued background job in logs.
  config.active_job.verbose_enqueue_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Raise error when a before_action's only/except options reference missing actions
  config.action_controller.raise_on_missing_callback_actions = true

  # Check html is valid
  config.middleware.use HTMLProofer::Middleware

  # raise an error if assets aren't found
  config.assets.unknown_asset_fallback = false
  config.assets.check_precompiled_asset = false

  # enable Resque logging
  Resque.logger       = Logger.new(STDOUT)
  Resque.logger.level = Logger::INFO
end
