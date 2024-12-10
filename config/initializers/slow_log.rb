# frozen_string_literal: true
# log excessively slow events to make debugging & optimization easier.
# ideally this will be replaced by proper metrics at some future point.

ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  next if event.duration <= 5000

  # hide most headers as they significantly clutter logs
  headers = event.payload.delete(:headers).to_h
  event.payload[:partial_headers] = headers.slice("HTTP_USER_AGENT", "REMOTE_ADDR")
  Rails.logger.warn "[process_action.action_controller] SLOW: action took longer than 5 seconds: #{event.payload}"
end

ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  next if event.duration <= 1000

  # convert activerecord binds into more readable parameters
  # filter out sensitive parameters
  # structure of :binds is an array of ActiveModel::Attribute (allowing us to filter sensitive attribute names), or raw values
  # structure of :type_casted_binds is an array of raw values (enums converted to ints, etc)
  filter_keys = ["salt_uuid", "crypted", "email"]
  filter_values = event.payload[:binds].filter_map do |x|
    x.value if x.is_a?(ActiveModel::Attribute) && filter_keys.include?(x.name.to_s)
  end

  event.payload[:binds] = event.payload[:binds].map do |x|
    value = x.is_a?(ActiveModel::Attribute) ? x.value : x
    filter_values.include?(value) ? 'EXCLUDED' : value
  end
  event.payload[:type_casted_binds] = event.payload[:type_casted_binds].map do |value|
    filter_values.include?(value) ? 'EXCLUDED' : value
  end
  Rails.logger.warn "[sql.active_record] SLOW: sql took longer than 1 second: #{event.payload}"
rescue StandardError => e
  Rails.logger.error "[sql.active_record] SLOW: error in logging: #{e}"
  ExceptionNotifier.notify_exception(e, data: { location: "slow query subscriber", args: args })
end

ActiveSupport::Notifications.subscribe("instantiation.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  detail_string = "#{event.payload[:class_name]}, #{event.payload[:record_count]}"
  Rails.logger.warn "[instantiation.active_record] SLOW: many records created: #{detail_string}" if event.payload[:record_count] > 70
  Rails.logger.warn "[instantiation.active_record] SLOW: instantiation took more than 1 second: #{detail_string}" if event.duration > 1000
end
