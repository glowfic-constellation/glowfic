require "spec_helper"

RSpec.feature "Logging out", :type => :feature do
  scenario "Log out while correctly logged in" do
    user = login
    expect(page).to have_selector('#user-info', text: user.username)
    # TODO: Use js:true and logout button, rather than manually submitting a DELETE.
    page.driver.submit(:delete, logout_path, {})

    expect(page).to have_selector('.flash.success', text: 'You have been logged out.')
    expect(page).to have_no_selector('#user-info')
    expect(page).to have_current_path(root_path)

    # make sure we're still logged out after navigating somewhere else
    visit boards_path
    expect(page).to have_no_selector('.flash')
    expect(page).to have_no_selector('#user-info')
  end
end
