RSpec.describe "Logging out" do
  scenario "Log out while correctly logged in", :js do
    user = login

    expect(page).to have_selector('#user-info', text: user.username)

    click_button "Log out"
    page.accept_confirm

    aggregate_failures do
      expect(page).to have_selector('.flash.success', text: 'You have been logged out.')
      expect(page).to have_no_selector('#user-info')
      expect(page).to have_current_path(root_path)
    end

    # make sure we're still logged out after navigating somewhere else
    visit continuities_path

    aggregate_failures do
      expect(page).to have_selector('.table-title', text: 'Continuities')
      expect(page).to have_no_selector('.flash')
      expect(page).to have_no_selector('#user-info')
    end
  end
end
