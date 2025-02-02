require 'devise'
Devise # rubocop:disable Lint/Void

module Devise
  def self.mappings
    # Starting from Rails 8.0, routes are lazy-loaded by default in test and development environments.
    # However, Devise's mappings are built during the routes loading phase.
    # To ensure it works correctly, we need to load the routes first before accessing @@mappings.
    # See devise/issues/5705
    Rails.application.try(:reload_routes_unless_loaded)
    @@mappings
  end
end
