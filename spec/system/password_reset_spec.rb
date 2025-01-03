RSpec.describe "Resetting password" do
  before(:each) { ResqueSpec.reset! }

  scenario "Resetting your password" do
    # request reset
    user = create(:user)
    visit new_user_password_path
    expect(page).to have_selector("th.table-title", exact_text: "Forgot your password?")
    within(".form-table") do
      fill_in "Email", with: user.email
      click_button "Reset password"
    end
    expect(page).to have_selector('.notice', exact_text: 'A password reset link has been emailed to you.')

    expect(DeviseMailer).to have_queue_size_of(1)

    # complete reset request
    # NB. can't pull from the database as the token there is hashed - must pull the token direct from the mail
    # https://github.com/heartcombo/devise/blob/v4.9.4/lib/devise/models/recoverable.rb#L134
    token = ResqueSpec.queue_for(DeviseMailer).last[:args][1][1]
    visit edit_user_password_path(user, reset_password_token: token)
    expect(page).to have_selector("th.table-title", exact_text: "Change your password")
    fill_in "New Password", with: 'anewpass'
    fill_in "Confirm Password", with: 'anewpass'
    click_button "Change my password"
    expect(page).to have_selector('.flash', text: "Password changed.")
    expect(user.reload.valid_password?('anewpass')).to be true
  end
end
