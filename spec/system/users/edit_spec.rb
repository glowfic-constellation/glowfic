RSpec.describe "Editing account settings" do
  let(:user) { create(:user, username: 'John Doe', email: 'dummy@example.com') }

  scenario "Logged-out user tries to edit a user" do
    visit edit_user_path(user)
    expect(page).to have_selector('.flash.error', exact_text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
  end

  scenario "User tries to edit a different user" do
    login
    visit edit_user_path(user)
    expect(page).to have_selector('.flash.error', exact_text: 'You do not have permission to modify this account.')
    expect(page).to have_current_path(continuities_path)
  end

  scenario "User edits themself", :js do
    login(user)
    visit edit_user_path(user)
    expect(page).to have_selector('.editor-title', exact_text: 'Settings')
    expect(page).to have_no_selector('.flash.error')

    find_by_id("user_default_hide_edit_delete_buttons").click
    within("#edit_user_#{user.id}") { click_button 'Save' }
    # Save reloads the page, so re-query the checkboxes via page matchers (which
    # re-find + wait) rather than holding now-stale element references.
    expect(page).to have_checked_field("user_default_hide_edit_delete_buttons")
    expect(page).to have_unchecked_field("user_default_hide_add_bookmark_button")

    find_by_id('user_default_hide_add_bookmark_button').click
    find_by_id("user_default_hide_edit_delete_buttons").click
    within("#edit_user_#{user.id}") { click_button 'Save' }
    expect(page).to have_unchecked_field("user_default_hide_edit_delete_buttons")
    expect(page).to have_checked_field("user_default_hide_add_bookmark_button")

    # TODO all fields
    # within("#edit_user_#{user.id}") do
    #   expect(page).to have_field('Username', with: 'John Doe')
    #   expect(page).to have_field('Email address', with: 'dummy@example.com')
    #   fill_in 'Username', with: 'Jane Doe'
    #   fill_in "Email address", with: "dummy2@example.com"
    # end
  end
end
