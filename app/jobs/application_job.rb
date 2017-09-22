require 'resque/errors'
class ApplicationJob < ActiveJob::Base
  extend Resque::Plugins::Retry

  give_up_callback :notify_exception

  give_up_callback do |e| puts e end
  try_again_callback do |e| puts e end

  around_perform :retry_on_term

  def retry_on_term
    yield
  rescue Resque::TermException
    Rails.logger.error("Performing #{self.class} was terminated. Retrying...")
    retry_job
  end

  def self.notify_exception(exception, *args)
    Rails.logger.error("Received #{exception}, job #{self.name} failed with #{args}")
    ExceptionNotifier.notify_exception(exception, data: {job: self.name, args: args})
  end
end
