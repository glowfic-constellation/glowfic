# typed: true
# frozen_string_literal: true

require "active_support/core_ext/integer/time"
require "barnes"
require "bundler/setup"
require "capybara/rspec"
require "exception_notification/resque"
require "factory_bot_rails"
require "rails/all"
require "rails/pagination"
require "resque/errors"
require "resque/failure/multiple"
require "resque/failure/redis"
require "resque/server"
require "rspec/rails"
require "simplecov"
require "webmock/rspec"
require "will_paginate/array"
require "will_paginate/view_helpers/action_view"
require "will_paginate/view_helpers/link_renderer"

require_relative "../../config/initializers/will_paginate"
