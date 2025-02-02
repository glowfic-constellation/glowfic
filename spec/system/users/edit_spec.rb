RSpec.describe "Editing account settings" do
  include ActionMailer::TestHelper

  let(:user) { create(:user, username: 'John Doe', password: known_test_password, email: 'dummy@example.com') }

  scenario "Logged-out user tries to edit a user" do
    visit edit_user_path(user)
    expect(page).to have_selector('.error', text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
  end

  scenario "User tries to edit a different user" do
    login
    visit edit_user_path(user)
    expect(page).to have_selector('.error', text: 'You do not have permission to modify this account.')
    expect(page).to have_current_path(continuities_path)
  end

  scenario "User edits themself", :js do
    login(user, known_test_password)
    visit edit_user_path(user)
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.editor-title', exact_text: 'Settings')

    hide_edit_delete_buttons = find_by_id("user_default_hide_edit_delete_buttons")
    hide_add_bookmark_button = find_by_id('user_default_hide_add_bookmark_button')
    hide_edit_delete_buttons.click
    within("#edit_user_#{user.id}") { click_button 'Save' }
    expect(hide_edit_delete_buttons).to be_checked
    expect(hide_add_bookmark_button).not_to be_checked
    hide_add_bookmark_button.click
    hide_edit_delete_buttons.click
    within("#edit_user_#{user.id}") { click_button 'Save' }
    expect(hide_edit_delete_buttons).not_to be_checked
    expect(hide_add_bookmark_button).to be_checked

    # TODO all fields
    # within("#edit_user_#{user.id}") do
    #   expect(page).to have_field('Username', with: 'John Doe')
    #   expect(page).to have_field('Email address', with: 'dummy@example.com')
    #   fill_in 'Username', with: 'Jane Doe'
    #   fill_in "Email address", with: "dummy2@example.com"
    # end
  end

  scenario "User edits their email and password" do
    clear_enqueued_jobs

    login(user, known_test_password)
    new_password = known_test_password + "new"
    old_email = user.email
    new_email = "different" + user.email

    visit edit_user_path(user)
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.editor-title', exact_text: 'Settings')
    expect(page).to have_text(old_email)

    click_link "Change Email or Password"
    expect(page).to have_selector(".editor-title", exact_text: "Change Email or Password")
    click_button "Save"
    expect(page).to have_selector(".flash.error", text: "Current password can't be blank")

    fill_in "Old", with: new_password
    click_button "Save"
    expect(page).to have_selector(".flash.error", text: "Current password is invalid")

    fill_in "Old", with: known_test_password
    click_button "Save"
    expect(page).to have_selector(".flash.notice", text: "Account updated.")
    assert_enqueued_emails 0

    visit edit_user_path(user)
    click_link "Change Email or Password"
    fill_in "Old", with: known_test_password
    fill_in "New", with: known_test_password
    fill_in "Confirm", with: known_test_password
    expect {
      click_button "Save"
    }.to have_enqueued_email(DeviseMailer, :password_change)
    expect(page).to have_selector(".flash.notice", text: "Account updated.")
    clear_enqueued_jobs

    visit edit_user_path(user)
    click_link "Change Email or Password"
    fill_in "Old", with: known_test_password
    fill_in "New", with: new_password
    fill_in "Confirm", with: new_password
    expect {
      click_button "Save"
    }.to have_enqueued_email(DeviseMailer, :password_change)
    expect(page).to have_selector(".flash.notice", text: "Account updated.")
    clear_enqueued_jobs

    visit edit_user_path(user)
    click_link "Change Email or Password"
    fill_in "Old", with: known_test_password
    click_button "Save"
    expect(page).to have_selector(".flash.error", text: "Current password is invalid")

    visit edit_user_path(user)
    click_link "Change Email or Password"
    fill_in "Old", with: new_password
    fill_in "Email", with: new_email
    click_button "Save"
    expect(page).to have_selector(".flash.notice",
      text: "Account updated. A confirmation link has been emailed to you; use this to confirm your new email.",)
    mail_args = deserialize_enqueued_mail(mail_queue.last)
    token = mail_args[-1][:args][1]
    visit user_confirmation_path(confirmation_token: token)
    expect(page).to have_current_path(root_path)
    expect(page).to have_selector('.flash.notice', text: "Email address confirmed.")

    visit edit_user_path(user)
    expect(page).to have_text(new_email)
  end
end
