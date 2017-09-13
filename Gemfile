source 'https://rubygems.org'

ruby '2.4.1'

gem 'api-pagination'
gem 'apipie-rails'
gem 'audited-activerecord', '~> 4.0'
gem 'aws-sdk-s3', '~> 1'
#gem 'aws-sdk-cloudfront', '~> 1'
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
gem 'rails', '~> 4.2.9'
gem 'rack-pratchett'
gem 'redis-rails'
gem 'resque'
gem 'resque_mailer'
gem 'resque-retry'
gem 'resque-web', require: 'resque_web'
gem 'sass-rails'
gem 'select2-rails'
gem 'test-unit', '~> 3.0' # required by Heroku for production console
gem 'tinymce-rails'
gem 'uglifier'
gem 'will_paginate'

group :production do
  gem 'puma'
  gem 'rack-cors'
  gem 'rack-timeout'
  gem 'rails_12factor'
  gem 'tunemygc'
end

group :development do
  gem 'web-console', '~> 2.0'
  gem 'rack-mini-profiler'
  gem 'memory_profiler'
end

group :development, :test do
  gem 'byebug'
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'dotenv-rails'
  gem 'rake', '~> 12.0'
  gem 'seed_dump', '~> 3.2'
  gem 'thin'
  gem 'rspec-rails'
end

group :test do
  gem 'codeclimate-test-reporter', '~> 1.0.0'
  gem 'factory_girl_rails'
  gem 'json'
  gem 'resque_spec'
  gem 'simplecov'
  gem 'timecop'
  gem 'webmock'
end
