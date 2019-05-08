source 'https://rubygems.org'

ruby '2.6.2'

gem 'api-pagination'
gem 'apipie-rails'
gem 'audited', '~> 4.5'
gem 'aws-sdk-rails', '~> 2'
gem 'aws-sdk-s3', '~> 1'
gem 'aws-sdk-ses', '~> 1'
gem 'bootstrap'
gem 'browser'
gem 'coffee-rails'
gem 'exception_notification'
gem 'gon'
gem 'haml-rails'
gem 'httparty'
gem 'jquery-fileupload-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'newrelic_rpm'
gem 'nilify_blanks'
gem 'nokogiri'
gem 'pg', '~> 0.21.0'
gem 'pg_search'
gem 'rack-pratchett'
gem 'rails', '~> 5.2.0'
gem 'redis', '~> 3.3.5' # until resque updates to support Redis 4
gem 'redis-rails'
gem 'resque'
gem 'resque-scheduler'
gem 'resque-web', require: 'resque_web'
gem 'resque_mailer'
gem 'sanitize'
gem 'sass-rails'
gem 'select2-rails'
gem 'test-unit', '~> 3.0' # required by Heroku for production console
gem 'tinymce-rails', '~> 4.6.7'
gem 'uglifier'
gem 'will_paginate'

group :production do
  gem 'puma'
  gem 'rack-cors'
  gem 'rack-timeout'
  gem 'rails_12factor'
end

group :development do
  gem 'haml-lint', require: false
  gem 'listen'
  gem 'memory_profiler'
  gem 'rack-mini-profiler'
  gem 'rubocop', '~> 0.68.1'
  gem 'rubocop-performance', '~> 1.2.0'
  gem 'traceroute'
  gem 'web-console', '~> 3.0'
end

group :development, :test do
  gem 'byebug'
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'rake', '~> 12.0'
  gem 'rspec-rails'
  gem 'seed_dump', '~> 3.2'
  gem 'thin'
end

group :test do
  gem 'capybara'
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'factory_bot_rails'
  gem 'json'
  gem 'rails-controller-testing'
  gem 'resque_spec'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end
