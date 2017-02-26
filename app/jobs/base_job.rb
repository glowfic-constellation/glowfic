require 'resque/errors'

class BaseJob < Object
  extend Resque::Plugins::Retry

  give_up_callback :notify_exception

  def self.perform(*args)
    self.process(*args)
  rescue Resque::TermException
    Rails.logger.error("Performing #{self} was terminated. Retrying...")
    Resque.enqueue(self, *args)
  end

  def self.process(*args)
    raise NotImplementedError
  end

  def self.notify_exception(exception, *args)
    Rails.logger.error("Received #{exception}, job #{self.name} failed with #{args}")
    ExceptionNotifier.notify_exception(exception, data: {job: self.name, args: args})
  end

  def self.queue
    @queue
  end
end
