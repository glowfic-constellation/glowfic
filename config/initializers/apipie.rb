# frozen_string_literal: true
Apipie.configure do |config|
  config.app_name                = "Glowfic"
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/docs"
  config.api_controllers_matcher = Rails.root.join('app', 'controllers', 'api', "**", "*.rb")
  config.show_all_examples       = true
  config.languages               = ['en']
  config.default_locale          = 'en'
end
