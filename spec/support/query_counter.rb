# frozen_string_literal: true
module QueryCounter
  IGNORED = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE SAVEPOINT|SHOW|SET)\b/i

  def count_queries
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |_name, _start, _finish, _id, payload|
      next if payload[:cached]
      next if payload[:name] == 'SCHEMA'
      next if payload[:sql].match?(IGNORED)
      queries << payload[:sql]
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber) if subscriber
  end
end

RSpec.configure do |config|
  config.include QueryCounter
end
