RSpec.describe "Creating a new template" do
  scenario "Create an invalid template" do
    # view new template form without being logged in
    visit new_template_path

    expect(page).to have_selector('.flash.error', exact_text: 'You must be logged in to view that page.')

    # view new template form with no characters
    user = login
    visit new_template_path

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'New Template')
      expect(page).to have_no_selector('.sub', text: 'Characters')
      expect(page).to have_no_selector('.flash.error')
    end

    # view new template form with no untemplated characters
    create(:template_character, user: user)
    visit new_template_path

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'New Template')
      expect(page).to have_no_selector('.sub', text: 'Characters')
      expect(page).to have_no_selector('.flash.error')
    end

    # view new template form with untemplated characters
    create(:character, user: user)
    visit new_template_path

    aggregate_failures do
      expect(page).to have_selector('.sub', text: 'Characters')
      expect(page).to have_no_selector('.flash.error')
    end

    # create template with no data
    within('.form-table') do
      click_button 'Save'
    end

    error_message = "Template could not be created because of the following problems:\nName can't be blank"
    expect(page).to have_selector('.flash.error', exact_text: error_message)
  end

  scenario "Create a simple template" do
    login
    visit new_template_path

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'New Template')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      fill_in 'Template Name', with: 'Example template'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Template created.')
      expect(page).to have_no_selector('.flash.error')
    end
  end

  scenario "Create template with description and characters" do
    user = login
    other_template = create(:template, user: user)
    create(:character, user: user, template: other_template) # other_template_character
    Array.new(5) { |i| create(:character, user: user, name: "Character#{i + 1}") } # characters

    # create invalid template with characters and description
    visit new_template_path
    within('.form-table') do
      expect(page).to have_field('Template Name')

      fill_in 'template_description', with: 'Example template description'
      check('Character1')
      check('Character5')
      click_button 'Save'
    end

    aggregate_failures do
      error_message = "Template could not be created because of the following problems:\nName can't be blank Characters is invalid"
      expect(page).to have_selector('.flash.error', exact_text: error_message)

      within('.form-table') do
        expect(page).to have_field('Template Name', with: '')
        expect(page).to have_field('template_description', with: 'Example template description')
        expect(page).to have_checked_field('Character1')
        expect(page).to have_unchecked_field('Character2')
        expect(page).to have_unchecked_field('Character3')
        expect(page).to have_unchecked_field('Character4')
        expect(page).to have_checked_field('Character5')
      end
    end

    # save valid template with description and characters
    within('.form-table') do
      fill_in 'Template Name', with: 'Example template'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Template created.')
      expect(page).to have_no_selector('.flash.error')
    end
  end
end
