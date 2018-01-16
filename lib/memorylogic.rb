module Memorylogic
  def self.included(klass)
    klass.class_eval do
      before_action :log_memory_usage
      after_action :log_memory_usage
    end
  end

  class << self
    include ActionView::Helpers::NumberHelper
  end

  def self.memory_usage
    number_to_human_size(`ps -o rss= -p #{Process.pid}`.to_i)
  end

  private

    def log_memory_usage
      if logger
        logger.warn("Memory usage in #{params[:controller]}\##{params[:action]}: #{Memorylogic.memory_usage} | PID: #{Process.pid}")
      end
    end
end
