# log excessively slow events to make debugging & optimization easier.
# ideally this will be replaced by proper metrics at some future point.

ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  next unless event.duration > 5000

  # hide most headers as they significantly clutter logs
  headers = event.payload.delete(:headers).to_h
  event.payload[:partial_headers] = headers.slice("HTTP_USER_AGENT", "REMOTE_ADDR")
  Rails.logger.warn "[#{event.name}] SLOW: action took longer than 5 seconds: #{event.payload}"
end

ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  next if event.payload[:name] == 'SCHEMA'
  Rails.logger.debug "[#{event.name}] MEM: #{Mem.get_mem_string} <- #{event.payload[:name] || event.payload[:sql]}"
  next unless event.duration > 1000

  # convert activerecord binds into more readable parameters
  filter_keys = ["salt_uuid", "crypted", "email"]
  event.payload[:binds] = event.payload[:binds].map { |x| [x.name, x.value] }
  filter_values = event.payload[:binds].select { |x| filter_keys.include? x.first.to_s }.map { |x| x.last }

  event.payload[:binds] = event.payload[:binds].map do |x|
    [x.first, filter_values.include?(x.last) ? 'EXCLUDED' : x.last]
  end
  event.payload[:type_casted_binds] = event.payload[:type_casted_binds].map do |x|
    filter_values.include?(x) ? 'EXCLUDED' : x
  end
  Rails.logger.warn "[#{event.name}] SLOW: sql took longer than 1 second: #{event.payload}"
end

module Mem
  class << self
    include ActionView::Helpers::NumberHelper

    def get_mem_string
      number_to_human_size(GetProcessMem.new.bytes)
    end
  end
end

ActiveSupport::Notifications.subscribe("instantiation.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  detail_string = "#{event.payload[:class_name]}, #{event.payload[:record_count]}"
  Rails.logger.debug "[#{event.name}] MEM: #{Mem.get_mem_string} <- #{detail_string}"
  if event.payload[:record_count] > 70
    Rails.logger.warn "[#{event.name}] SLOW: many records created: #{detail_string}"
  end
  if event.duration > 1000
    Rails.logger.warn "[#{event.name}] SLOW: instantiation took more than 1 second: #{detail_string}"
  end
end

log_render = Proc.new do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  detail_string = event.payload[:identifier]
  Rails.logger.debug "[#{event.name}] MEM: #{Mem.get_mem_string} <- #{detail_string}"
end

ActiveSupport::Notifications.subscribe("render_template.action_view", &log_render)
ActiveSupport::Notifications.subscribe("render_partial.action_view", &log_render)
ActiveSupport::Notifications.subscribe("render_collection.action_view", &log_render)
