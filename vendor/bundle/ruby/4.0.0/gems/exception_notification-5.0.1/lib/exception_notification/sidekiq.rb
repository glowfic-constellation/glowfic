# frozen_string_literal: true

require "sidekiq"

::Sidekiq.configure_server do |config|
  config.error_handlers << proc do |ex, context, config|
    # Before Sidekiq 7.1.5 the config was not passed to the proc
    if config
      ExceptionNotifier.notify_exception(ex, data: {sidekiq: {context: context, config: config}})
    else
      ExceptionNotifier.notify_exception(ex, data: {sidekiq: context})
    end
  end
end
