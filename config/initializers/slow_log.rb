# log excessively slow events to make debugging & optimization easier.
# ideally this will be replaced by proper metrics at some future point.

ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  next unless event.duration > 5000

  # hide most headers as they significantly clutter logs
  headers = event.payload.delete(:headers).to_h
  event.payload[:partial_headers] = headers.slice("HTTP_USER_AGENT", "REMOTE_ADDR")
  Rails.logger.warn "[process_action.action_controller] SLOW: action took longer than 5 seconds: #{event.payload}"
end

ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  next unless event.duration > 1000

  # convert activerecord binds into more readable parameters
  event.payload[:binds] = event.payload[:binds].map { |x| [x.name, x.value] }
  Rails.logger.warn "[sql.active_record] SLOW: sql took longer than 1 second: #{event.payload}"
end

ActiveSupport::Notifications.subscribe("instantiation.active_record") do |*args|
  event = ActiveSupport::Notifications::Event.new *args
  detail_string = "#{event.payload[:class_name]}, #{event.payload[:record_count]}"
  if event.payload[:record_count] > 70
    Rails.logger.warn "[instantiation.active_record] SLOW: many records created: #{detail_string}"
  end
  if event.duration > 1000
    Rails.logger.warn "[instantiation.active_record] SLOW: instantiation took more than 1 second: #{detail_string}"
  end
end
