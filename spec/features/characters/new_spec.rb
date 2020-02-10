require "spec_helper"

RSpec.feature "Creating a new character", :type => :feature do
  def complex_objects(user)
    create_list(:icon, 2, user: user)
    create_list(:template, 2, user: user)
    create_list(:setting, 2)
    icon = create(:icon, user: user, keyword: 'Example icon')
    template = create(:template, user: user, name: 'Example template')
    create(:setting, name: 'Example setting')
    create(:setting, name: 'Example setting 2')
    [template, icon]
  end

  def complex_setup
    # create character with no name
    find("img[alt='Example icon']").click
    expect(page).to have_selector('.selected-icon')
    expect(find('.selected-icon')[:alt]).to eq('Example icon')

    select2('Setting', 'Example setting', 'Example setting 2')

    within('.form-table') do
      fill_in 'Template Nickname', with: 'Example nickname'
      fill_in 'Screen Name', with: 'example_screenname'
      fill_in 'Facecast', with: 'Example facecast'
      fill_in 'Description', with: 'Example description'
    end
  end

  scenario "Create an invalid character", js: true do
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

    complex_objects(user)

    # view new character form with icons
    visit new_character_path

    expect(page).to have_selector("img.icon", count: 3)
    select2('#character_template_id', 'Example template')
    complex_setup
    click_button 'Save'

    expect(page).to have_selector('.flash.error')
    within('.flash.error') do
      expect(page).to have_text('Your character could not be saved.')
      expect(page).to have_text('Name can\'t be blank')
    end

    # check that it preserved inputs
    expect(page).to have_selector('.selected-icon')
    expect(find('.selected-icon')[:alt]).to eq('Example icon')

    within('.form-table') do
      expect(page).to have_field('Template Nickname', with: 'Example nickname')
      expect(page).to have_field('Screen Name', with: 'example_screenname')
      expect(page).to have_field('Facecast', with: 'Example facecast')
      expect(page).to have_field('Description', with: 'Example description')
      expect(page).to have_multiselect('#character_setting_ids', with: ['Example setting', 'Example setting 2'])
      expect(page).to have_select2('#character_template_id', with: 'Example template')
    end
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

  scenario "Creating character with icon, description and extant template", js: true do
    user = login
    template, icon = complex_objects(user)

    visit new_character_path(template_id: template.id)

    complex_setup

    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_select2('Template', selected: 'Example template')

    fill_in 'Character Name', with: 'Example character'
    click_button 'Save'

    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.flash.success')
    within('.flash.success') do
      expect(page).to have_text('Character saved successfully.')
    end

    within('.character-info-box') do
      expect(page).to have_selector('.character-name', text: 'Example character')
      expect(page).to have_selector('.character-screenname', text: 'example_screenname')
      expect(page).to have_selector('.character-icon')

      within('.character-icon') do
        expect(page).to have_selector("a[href='/icons/#{icon.id}']")
        expect(find('img')[:alt]).to eq('Example icon')
      end
    end

    within('.character-right-content-box') do
      expect(page).to have_selector('.character-template', text: 'Example template')
      expect(page).to have_selector('.character-pb', text: 'Example facecast')
      expect(page).to have_selector('.character-description', text: 'Example description')
      expect(page).to have_selector('.character-setting', text: 'Example setting, Example setting 2')
    end
  end

  scenario "Creating character with new template" do
    login
    visit new_character_path
    expect(page).to have_no_selector('.flash.error')
    within('.form-table') do
      fill_in 'Character Name', with: 'Example character'
      check 'new_template'
      fill_in 'Template Name', with: 'Example template'
      click_button 'Save'
    end
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.flash.success')
    within('.flash.success') do
      expect(page).to have_text('Character saved successfully.')
    end
    expect(page).to have_selector('.character-template', text: 'Example template')
  end
end
