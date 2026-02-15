RSpec.describe "Seeding database" do
  scenario "Loading seed data throws no errors" do
    allow(STDOUT).to receive(:puts)
    DatabaseCleaner.clean_with(:truncation)
    expect { Rails.application.load_seed }.not_to raise_error
  end
end
