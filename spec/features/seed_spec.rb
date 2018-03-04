require "spec_helper"

RSpec.feature "Seeding database", :type => :feature do
  scenario "Loading seed data throws no errors" do
    allow(STDOUT).to receive(:puts)
    DatabaseCleaner.clean_with(:truncation)
    Rails.application.load_seed
  end
end
