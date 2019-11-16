require "spec_helper"

RSpec.feature "Creating a new character", :type => :feature do
  scenario "Create an invalid character" do
    # view new character form without being logged in
    visit new_character_path
    expect(page).to have_selector('.flash.error')
    within('.flash.error') do
      expect(page).to have_text("You must be logged in")
    end

    # view new character form with no icons
    user = login
    visit new_character_path
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_no_text("You must be logged in")
    expect(page).to have_selector("th", text: "New Character")
    expect(page).to have_no_selector("img.icon")

    # view new character form with icons
    create_list(:icon, 2, user: user)
    visit new_character_path
    expect(page).to have_selector("img.icon", count: 2)

    # create character with no data
    within('.form-table') do
      click_button 'Save'
    end
    expect(page).to have_selector('.flash.error')
    within('.flash.error') do
      expect(page).to have_text('Your character could not be saved.')
      expect(page).to have_text('Name can\'t be blank')
    end

    # TODO: it saves inputs
  end

  scenario "Create a simple character" do
    login
    visit new_character_path
    expect(page).to have_no_selector('.flash.error')
    within('.form-table') do
      fill_in 'Character Name', with: 'Example character'
      click_button 'Save'
    end
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.flash.success')
    within('.flash.success') do
      expect(page).to have_text('Character saved successfully.')
    end
  end

  scenario "Creating character with icon, description and extant template"

  scenario "Creating character with new template"
end
