RSpec.describe "Resetting password" do
  include ActionMailer::TestHelper

  scenario "Resetting your password" do
    # request reset
    user = create(:user)
    visit new_user_password_path
    expect(page).to have_selector('.editor-title', exact_text: "Forgot your password?")
    within('.form-table') do
      fill_in "Email", with: user.email
      expect {
        click_button "Reset password"
      }.to have_enqueued_email(DeviseMailer, :reset_password_instructions)
    end
    expect(page).to have_selector('.notice', exact_text: 'A password reset link has been emailed to you.')

    # complete reset request
    # NB. can't pull from the database as the token there is hashed - must pull the token direct from the mail
    # https://github.com/heartcombo/devise/blob/v4.9.4/lib/devise/models/recoverable.rb#L134
    mail_args = deserialize_enqueued_mail(mail_queue.last)
    token = mail_args[-1][:args][1]
    visit edit_user_password_path(user, reset_password_token: token)
    expect(page).to have_selector('.editor-title', exact_text: "Change your password")
    fill_in "New Password", with: 'anewpass'
    fill_in "Confirm Password", with: 'anewpass'
    click_button "Change my password"
    expect(page).to have_selector('.flash', text: "Password changed.")
    expect(user.reload.valid_password?('anewpass')).to be true
  end
end
