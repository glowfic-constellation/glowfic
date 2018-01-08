# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Affects as_json by using a root object and key before the data
ActiveRecord::Base.include_root_in_json = false
