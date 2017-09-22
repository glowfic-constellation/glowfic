require 'resque/errors'
class ApplicationJob < ActiveJob::Base
  extend Resque::Plugins::Retry

  give_up_callback :notify_exception

  rescue_from(Resque::TermException) do
    Rails.logger.error("Performing #{self.class} was terminated. Retrying...")
    retry_job
  end

  def self.notify_exception(exception, *args)
    Rails.logger.error("Received #{exception}, job #{self.name} failed with #{args}")
    ExceptionNotifier.notify_exception(exception, data: {job: self.name, args: args})
  end
end
