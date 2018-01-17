# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!
require 'rspec/page-regression'

# monkey patch rspec-page-regression after Rails 5.1 upgrade
module RSpec::PageRegression
  class FilePaths
    def initialize(example, expected_path = nil)
      expected_path = Pathname.new(expected_path) if expected_path

      descriptions = description_ancestry(example.metadata[:example_group])
      descriptions.push example.description unless example.description.parameterize(separator: '_') =~ %r{
       ^
       (then_+)?
       ( (expect_+) (page_+) (to_+) (not_+)? | (page_+) (should_+)? )
       match_expectation
       (_#{Regexp.escape(expected_path.to_s)})?
         $
      }xi
      canonical_path = descriptions.map{|s| s.parameterize(separator: '_')}.inject(Pathname.new(""), &:+)

      app_root = Pathname.new(example.metadata[:file_path]).realpath.each_filename.take_while{|c| c != "spec"}.inject(Pathname.new("/"), &:+)
      expected_root = app_root + "spec" + "expectation"
      test_root = app_root + "tmp" + "spec" + "expectation"
      cwd = Pathname.getwd

      @expected_image = expected_path || (expected_root + canonical_path + "expected.png").relative_path_from(cwd)
      @test_image = (test_root + canonical_path + "test.png").relative_path_from cwd
      @difference_image = (test_root + canonical_path + "difference.png").relative_path_from cwd
    end

    private

    def description_ancestry(metadata)
      return [] if metadata.nil?
      description_ancestry(metadata[:parent_example_group]) << metadata[:description].parameterize(separator: '_')
    end
  end
end

module Helpers
  def example_path(example)
    group_path(example.metadata[:example_group]) + example.description.parameterize(separator: "_")
  end

  def group_path(metadata)
    return Pathname.new("") if metadata.nil?
    group_path(metadata[:parent_example_group]) + metadata[:description].parameterize(separator: "_")
  end
end

require 'capybara/rspec'
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
