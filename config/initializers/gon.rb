# rubocop:disable all
class Gon
  # reverts gon 7.0's switch from request_store to ActiveSupport::CurrentAttributes
  # (https://github.com/gazay/gon/pull/167) for the same reason as config/initializers/audited.rb:
  # ActionController::TestCase wraps each simulated request in Rails.application.executor, whose
  # to_complete callback resets *all* CurrentAttributes classes - wiping gon's data before controller
  # specs can assert on `controller.gon.*` after the action runs.
  class Current
    def self.gon
      RequestStore.store[:gon]
    end

    def self.gon=(value)
      RequestStore.store[:gon] = value
    end

    def self.gon_keys_cache
      RequestStore.store[:gon_keys_cache]
    end

    def self.gon_keys_cache=(value)
      RequestStore.store[:gon_keys_cache] = value
    end
  end
end
# rubocop:enable all
