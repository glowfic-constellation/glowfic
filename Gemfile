# frozen_string_literal: true
source 'https://rubygems.org'

ruby '3.3.6'

gem 'api-pagination'
gem 'apipie-rails'

# when upgrading check:
# - for migrations with `rails generate audited:upgrade`
# - that the method set_audit_user has not changed, since we duplicate it in
#   ApplicationRecord for use in callbacks to send audit user ids to background jobs.
#   (currently https://github.com/collectiveidea/audited/blob/v5.8.0/lib/audited/audit.rb#L187)
# - the request store functionality hasn't changed: we use RequestStore instead of
#   ActiveSupport::CurrentAttributes to avoid issues with values being reset in tests when
#   executing jobs inline (currently overwriting
#   https://github.com/collectiveidea/audited/blob/v5.8.0/lib/audited.rb#L33)
gem 'audited', '~> 5.8.0'

gem 'aws-actionmailer-ses', '~> 1'
gem 'aws-sdk-rails', '~> 5'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-ses', '~> 1'
gem 'barnes' # heroku ruby-specific metrics
gem 'bootstrap', '~> 5.3' # pin until major version is handled
gem 'dartsass-sprockets'
gem 'exception_notification'
gem 'get_process_mem'
gem 'gon', '~> 6.4'
gem 'haml-rails'
gem 'httparty'
gem 'jquery-fileupload-rails'
gem 'jquery-rails', '~> 4.6'
gem 'jquery-ui-rails-dox-fork', require: 'jquery-ui-rails'
gem 'json', '~> 2.9'
gem 'jwt'
gem 'newrelic_rpm'
gem 'nilify_blanks'
gem 'nokogiri'
gem 'pg', '~> 1.5'
gem 'pg_search'
gem 'rack-pratchett'
gem 'rails', '~> 7.2.2'
gem "redcarpet", "~> 3.6"
gem 'redis', '~> 5.3'
gem 'request_store', '~> 1.7'
gem 'resque'
gem 'resque_mailer'
gem 'sanitize'
gem 'scout_apm'
gem 'select2-rails'
gem 'sprockets'
gem 'sprockets-rails'
gem 'terser'
gem 'test-unit', '~> 3.6' # required by Heroku for production console
gem 'tinymce-rails', '~> 7.5'
gem 'will_paginate'

group :production do
  gem 'puma'
  gem 'rack-attack'
  gem 'rack-cors'
  gem 'rack-timeout', '>= 0.6.0'
  gem 'resque-heroku-signals'
end

group :development do
  gem "brakeman", '~> 6.2.2', require: false
  gem 'haml_lint', '~> 0.59.0', require: false
  gem 'listen'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'rubocop', '~> 1.69.0', require: false
  gem 'rubocop-capybara', '~> 2.21.0', require: false
  gem 'rubocop-factory_bot', '~> 2.26.0', require: false
  gem 'rubocop-performance', '~> 1.23.0', require: false
  gem 'rubocop-rails', '~> 2.27.0', require: false
  gem 'rubocop-rspec', '~> 3.2.0', require: false
  gem 'rubocop-rspec_rails', '~> 2.30.0', require: false
  gem 'traceroute'
end

group :development, :test do
  gem 'byebug'
  gem 'database_cleaner'
  gem 'dotenv'
  gem 'html-proofer', '< 4'
  gem 'rake', '~> 13.2'
  gem 'rspec-rails'
  gem 'seed_dump', '~> 3.2'
end

group :test do
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'rails-controller-testing'
  gem 'resque_spec'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end
