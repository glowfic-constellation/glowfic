RSpec.describe "Editing a template" do
  let(:user) { create(:user) }
  let(:template) { create(:template, user: user, name: 'Example Template') }

  scenario "Logged out user tries to edit a template" do
    visit template_path(template)

    aggregate_failures do
      expect(page).to have_selector('.table-title', text: "Template: #{template.name}")
      expect(page).to have_no_link('Edit Template')
    end

    visit edit_template_path(template)

    aggregate_failures do
      expect(page).to have_selector('.flash.error', text: 'You must be logged in to view that page.')
      expect(page).to have_current_path(root_path)
      expect(page).to have_no_selector('.form-table')
    end
  end

  scenario "Editing a simple template" do
    login(user)
    visit edit_template_path(template)

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'Edit Template')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      fill_in 'Template Name', with: 'Renamed Template'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', text: 'Template updated.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.table-title', text: 'Template: Renamed Template')
    end
  end

  scenario "Editing an invalid template" do
    login(user)
    visit edit_template_path(template)

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'Edit Template')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      fill_in 'Template Name', with: ''
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.error', text: "Template could not be updated because of the following problems:\nName can't be blank")
      expect(page).to have_selector('.editor-title', text: 'Edit Template')
    end
  end

  scenario "Editing a template with description and characters" do
    create(:character, user: user, template: template, name: 'Stable Character')
    create(:character, user: user, template: template, name: 'Removed Character')
    create(:character, user: user, name: 'Added Character')
    create(:character, user: user, name: 'Unrelated Character')
    template.update!(description: 'This is a sample template with two characters.')

    login(user)
    visit edit_template_path(template)

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'Edit Template')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      check 'Added Character'
      uncheck 'Removed Character'
      fill_in 'Description', with: 'This is still a sample template.'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Template updated.')
      expect(page).to have_no_selector('.flash.error')

      within('.icons-box') do
        expect(page).to have_text('Stable Character')
        expect(page).to have_text('Added Character')
        expect(page).to have_no_text('Removed Character')
        expect(page).to have_no_text('Unrelated Character')
      end

      expect(page).to have_selector('.single-description', text: 'This is still a sample template.')
    end
  end
end
