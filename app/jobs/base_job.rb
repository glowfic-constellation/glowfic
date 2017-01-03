require 'resque/errors'

class BaseJob < Object
  def self.perform(*args)
    self.process(*args)
  rescue Resque::TermException
    Rails.logger.error("Performing #{self} was terminated. Retrying...")
    Resque.enqueue(self, *args)
  end

  def on_failure_retry(e, *args)
    Rails.logger.error("Performing #{self} caused an exception (#{e}). Retrying...")
    Resque.enqueue(self, *args)
  end
end
