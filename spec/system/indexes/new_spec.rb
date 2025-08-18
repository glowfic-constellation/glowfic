RSpec.describe "Creating a new index" do
  scenario "Create a simple index" do
    login
    visit new_index_path

    aggregate_failures do
      expect(page).to have_selector('.form-table')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      fill_in 'Index Name', with: 'Example index'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Index created.')
      expect(page).to have_no_selector('.flash.error')
    end
  end
end
