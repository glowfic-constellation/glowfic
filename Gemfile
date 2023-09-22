source 'https://rubygems.org'

ruby '3.2.2'

gem 'api-pagination'
gem 'apipie-rails'

# when upgrading check:
# - for migrations with `rails generate audited:upgrade`
# - that the method set_audit_user has not changed, since we duplicate it in
#   ApplicationRecord for use in callbacks to send audit user ids to background jobs.
#   (currently https://github.com/collectiveidea/audited/blob/v5.3.3/lib/audited/audit.rb#L183)
gem 'audited', '~> 5.3.3'

gem 'aws-sdk-rails', '~> 3'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-ses', '~> 1'
gem 'barnes' # heroku ruby-specific metrics
gem 'bootstrap', '~> 4.5' # pin until major version is handled
gem 'exception_notification'
gem 'get_process_mem'
gem 'gon', '~> 6.4'
gem 'haml-rails'
gem 'httparty'
gem 'jquery-fileupload-rails'
gem 'jquery-rails', '~> 4.6'
gem 'jquery-ui-rails'
gem 'json', '~> 2.6'
gem 'jwt'
gem 'newrelic_rpm'
gem 'nilify_blanks'
gem 'nokogiri'
gem 'pg', '~> 1.5'
gem 'pg_search'
gem 'rack-pratchett'
gem 'rails', '~> 6.1.0'
gem 'redis', '~> 4.0'
gem 'resque'
gem 'resque_mailer'
gem 'sanitize'
gem 'sassc-rails'
gem 'select2-rails'
gem 'sprockets'
gem 'test-unit', '~> 3.0' # required by Heroku for production console
gem 'tinymce-rails', '~> 5.10'
gem 'uglifier'
gem 'will_paginate'

group :production do
  gem 'puma'
  gem 'rack-cors'
  gem 'rack-timeout', '>= 0.6.0'
  gem 'resque-heroku-signals'
end

group :development do
  gem "brakeman", '~> 6.0.1', require: false
  gem 'haml_lint', '~> 0.45.0', require: false
  gem 'listen'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'rubocop', '~> 1.56.3', require: false
  gem 'rubocop-performance', '~> 1.18.0', require: false
  gem 'rubocop-rails', '~> 2.19.0', require: false
  gem 'rubocop-rspec', '~> 2.22.0', require: false
  gem 'traceroute'
end

group :development, :test do
  gem 'byebug'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'html-proofer'
  gem 'rake', '~> 13.0'
  gem 'rspec-rails'
  gem 'seed_dump', '~> 3.2'
  gem 'thin'
end

group :test do
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'fakeredis'
  gem 'rails-controller-testing'
  gem 'resque_spec'
  gem 'selenium-webdriver'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end
