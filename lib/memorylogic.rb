module Memorylogic
  def self.included(klass)
    klass.class_eval do
      around_action :log_memory_usage
    end
  end

  include ActionView::Helpers::NumberHelper

  private

  def log_memory_usage
    proc_mem = GetProcessMem.new
    old_memory = proc_mem.bytes
    yield
    new_memory = proc_mem.bytes

    change_string = "#{number_to_human_size(old_memory)} -> #{number_to_human_size(new_memory)}"
    diff = (new_memory - old_memory)
    return if diff == 0
    diff = (diff < 0 ? '-' : '+') + number_to_human_size(diff.abs)
    logger&.warn("Memory usage in #{params[:controller]}\##{params[:action]}: #{change_string} (#{diff}) | PID: #{Process.pid}")
  end
end
