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

# rubocop:disable all
module Apipie
  class MethodDescription
    private

    # replacing https://github.com/Apipie/apipie-rails/blob/v1.4.2/lib/apipie/method_description.rb#L219
    # forcing mutable string
    def format_example(ex)
      example = +""
      example << "// #{ex[:title]}\n" if ex[:title].present?
      example << "#{ex[:verb]} #{ex[:path]}"
      example << "?#{ex[:query]}" unless ex[:query].blank?
      example << "\n" << format_example_data(ex[:request_data]).to_s if ex[:request_data]
      example << "\n" << ex[:code].to_s
      example << "\n" << format_example_data(ex[:response_data]).to_s if ex[:response_data]
      example
    end
  end
end
# rubocop:enable all
