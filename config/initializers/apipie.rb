Apipie.configure do |config|
  config.app_name                = "Glowfic"
  config.api_base_url            = "/api/v1"
  config.doc_base_url            = "/docs"
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/**/*.rb"
  config.show_all_examples       = true
  config.default_locale          = nil
end
