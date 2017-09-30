require "spec_helper"

RSpec.feature "Creating a new character", :type => :feature do
  scenario "Create a new user" do
    visit new_character_path
    expect(page).to have_text("You must be logged in")

    user = login
    visit new_character_path
    expect(page).to have_no_text("You must be logged in")
    expect(page).to have_selector("th", text: "New Character")
    expect(page).to have_no_selector("img.icon")

    2.times do create(:icon, user: user) end
    visit new_character_path
    expect(page).to have_selector("img.icon", count: 2)
  end
end
