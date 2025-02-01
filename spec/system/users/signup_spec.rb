RSpec.describe "Signing up" do
  include ActionMailer::TestHelper

  scenario "works", :js do
    existing_user = create(:user)
    new_user_name = "new_user_name"
    new_user_password = "long password"
    visit root_path
    within("#header-buttons-links") { click_link "Sign up" }

    # Fill in all required fields
    within(".form-table") do
      fill_in "Username", with: ""
      click_button "Sign Up"
      within("#signup-username") { expect(page).to have_text("Please choose a username.") }

      fill_in "Username", with: existing_user.username
      click_button "Sign Up"
      within("#signup-username") { expect(page).to have_text("That username has already been taken.") }

      fill_in "Username", with: new_user_name
      fill_in "Email", with: ""
      within("#signup-username") { expect(page).to have_no_text("Please choose a username.") }
      click_button "Sign Up"
      within("#signup-email") { expect(page).to have_text("Please enter an email address.") }

      fill_in "Email", with: existing_user.email
      fill_in "Password", with: ""
      within("#signup-email") { expect(page).to have_no_text("Please enter an email address.") }
      click_button "Sign Up"
      within("#signup-password") { expect(page).to have_text("Please choose your password.") }

      fill_in "Password", with: "short"
      click_button "Sign Up"
      within("#signup-password") { expect(page).to have_text("Your password must be at least 6 characters long.") }

      fill_in "Password", with: new_user_password
      fill_in "Confirm", with: ""
      within("#signup-password") { expect(page).to have_no_text("Please choose your password.") }
      click_button "Sign Up"
      within("#signup-password-confirmation") { expect(page).to have_text("Your passwords do not match.") }

      fill_in "Confirm", with: "short"
      click_button "Sign Up"
      within("#signup-password-confirmation") { expect(page).to have_text("Your passwords do not match.") }

      fill_in "Confirm", with: new_user_password
      click_button "Sign Up"
      within("#signup-password-confirmation") { expect(page).to have_no_text("Your passwords do not match.") }
      click_button "Sign Up" # When clicking the first time it just deselected the input rather than actually clicking
      within("#signup-terms") { expect(page).to have_text("You must accept the Terms of Service to use the Constellation.") }

      check "Terms"
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error', text: "Please check your math and try again.")
    within(".form-table") do
      fill_in "Password", with: new_user_password
      fill_in "Confirm", with: new_user_password
      fill_in "Captcha", with: "14"
      fill_in "Secret (optional)", with: ENV.fetch("ACCOUNT_SECRET") + "different"
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error',
      text: "That is not the correct secret. Please ask someone in the community for help or leave blank to create a reader account.",)
    within(".form-table") do
      fill_in "Password", with: new_user_password
      fill_in "Confirm", with: new_user_password
      fill_in "Secret (optional)", with: ""
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error', text: "Email has already been taken")
    within(".form-table") do
      fill_in "Email", with: "different" + existing_user.email
      fill_in "Password", with: new_user_password
      fill_in "Confirm", with: new_user_password
      expect {
        click_button "Sign Up"
        click_button "Sign Up" # When clicking the first time it just deselected the input rather than actually clicking
      }.to have_enqueued_email(DeviseMailer, :confirmation_instructions)
    end
    expect(page).to have_selector('.flash.notice',
      text: "User created. A confirmation link has been emailed to you; use this to activate your account.",)
    expect(page).to have_current_path(root_path)

    # complete confirmation request
    # NB. can't pull from the database as the token there is hashed - must pull the token direct from the mail
    # https://github.com/heartcombo/devise/blob/v4.9.4/lib/devise/models/recoverable.rb#L134
    mail_args = deserialize_enqueued_mail(mail_queue.last)
    token = mail_args[-1][:args][1]
    visit user_confirmation_path(confirmation_token: token)
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_selector('.flash.notice', text: "Email address confirmed.")

    within(".form-table") do
      fill_in "Username", with: new_user_name
      fill_in "Password", with: new_user_password
      click_button "Sign In"
    end
    expect(page).to have_current_path(continuities_path)
    expect(page).to have_selector('.flash.notice', text: "You are now logged in. Welcome back!")
    within("#user-info") { expect(page).to have_text(new_user_name) }
    within("#header") do
      # Check that user is reader account
      expect(page).to have_link("Account")
      expect(page).to have_link("Favorites")
      expect(page).to have_no_link("Inbox")
      expect(page).to have_no_link("Notifications")
      expect(page).to have_no_link("Characters")
      expect(page).to have_no_link("Galleries")
      expect(page).to have_no_link("Post")
      expect(page).to have_no_link("Replies Owed")
    end
  end

  scenario "creates full user with secret", :js do
    new_user_name = "new_user_name"
    new_user_password = "long password"
    visit root_path
    within("#header-buttons-links") { click_link "Sign up" }

    # Fill in all required fields
    within(".form-table") do
      fill_in "Username", with: new_user_name
      fill_in "Email", with: "test@test.com"
      fill_in "Password", with: new_user_password
      fill_in "Confirm", with: new_user_password
      fill_in "Secret (optional)", with: ENV.fetch("ACCOUNT_SECRET")
      fill_in "Captcha", with: "14"
      check "Terms"
      expect {
        click_button "Sign Up"
      }.to have_enqueued_email(DeviseMailer, :confirmation_instructions)
    end

    expect(page).to have_selector('.flash.notice',
      text: "User created. A confirmation link has been emailed to you; use this to activate your account.",)
    expect(page).to have_current_path(root_path)

    # complete confirmation request
    # NB. can't pull from the database as the token there is hashed - must pull the token direct from the mail
    # https://github.com/heartcombo/devise/blob/v4.9.4/lib/devise/models/recoverable.rb#L134
    mail_args = deserialize_enqueued_mail(mail_queue.last)
    token = mail_args[-1][:args][1]
    visit user_confirmation_path(confirmation_token: token)
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_selector('.flash.notice', text: "Email address confirmed.")

    within(".form-table") do
      fill_in "Username", with: new_user_name
      fill_in "Password", with: new_user_password
      click_button "Sign In"
    end
    expect(page).to have_current_path(continuities_path)
    expect(page).to have_selector('.flash.notice', text: "You are now logged in. Welcome back!")
    within("#user-info") { expect(page).to have_text(new_user_name) }
    within("#header") do
      # Check that user is reader account
      expect(page).to have_link("Account")
      expect(page).to have_link("Favorites")
      expect(page).to have_link("Inbox")
      expect(page).to have_link("Notifications")
      expect(page).to have_link("Characters")
      expect(page).to have_link("Galleries")
      expect(page).to have_link("Post")
      expect(page).to have_link("Replies Owed")
    end
  end

  scenario "performs validations without javascript" do
    existing_user = create(:user)
    new_user_name = "new_user_name"
    new_user_password = "long password"
    visit root_path
    within("#header-buttons-links") { click_link "Sign up" }

    # Fill in all required fields
    within(".form-table") do
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error', text: "You must accept the Terms and Conditions to use the Constellation.")
    within(".form-table") do
      check "Terms"
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error', text: "Please check your math and try again.")
    within(".form-table") do
      fill_in "Captcha", with: "14"
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error', text: "Username can't be blank")
    expect(page).to have_selector('.flash.error', text: "Email can't be blank")
    expect(page).to have_selector('.flash.error', text: "Password can't be blank")
    within(".form-table") do
      fill_in "Username", with: existing_user.username
      fill_in "Email", with: existing_user.email
      fill_in "Password", with: "short"
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error', text: "Username has already been taken")
    expect(page).to have_selector('.flash.error', text: "Email has already been taken")
    expect(page).to have_selector('.flash.error', text: "Password confirmation doesn't match Password")
    expect(page).to have_selector('.flash.error', text: "Password is too short (minimum is 6 characters)")
    within(".form-table") do
      fill_in "Username", with: new_user_name
      fill_in "Email", with: "different" + existing_user.email
      fill_in "Password", with: "short"
      fill_in "Confirm", with: "short"
      click_button "Sign Up"
    end
    expect(page).to have_selector('.flash.error', text: "Password is too short (minimum is 6 characters)")
    within(".form-table") do
      fill_in "Password", with: new_user_password
      fill_in "Confirm", with: new_user_password
      expect {
        click_button "Sign Up"
      }.to have_enqueued_email(DeviseMailer, :confirmation_instructions)
    end
    expect(page).to have_selector('.flash.notice',
      text: "User created. A confirmation link has been emailed to you; use this to activate your account.",)
    expect(page).to have_current_path(root_path)

    # complete confirmation request
    # NB. can't pull from the database as the token there is hashed - must pull the token direct from the mail
    # https://github.com/heartcombo/devise/blob/v4.9.4/lib/devise/models/recoverable.rb#L134
    mail_args = deserialize_enqueued_mail(mail_queue.last)
    token = mail_args[-1][:args][1]
    visit user_confirmation_path(confirmation_token: token)
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_selector('.flash.notice', text: "Email address confirmed.")

    within(".form-table") do
      fill_in "Username", with: new_user_name
      fill_in "Password", with: new_user_password
      click_button "Sign In"
    end
    expect(page).to have_current_path(continuities_path)
    expect(page).to have_selector('.flash.notice', text: "You are now logged in. Welcome back!")
    within("#user-info") { expect(page).to have_text(new_user_name) }
  end

  scenario "resends email confirmation" do
    new_user_name = "new_user_name"
    new_user_password = "long password"
    new_user_email = "test@test.com"
    visit root_path
    within("#header-buttons-links") { click_link "Sign up" }

    # Fill in all required fields
    within(".form-table") do
      fill_in "Username", with: new_user_name
      fill_in "Email", with: new_user_email
      fill_in "Password", with: new_user_password
      fill_in "Confirm", with: new_user_password
      fill_in "Captcha", with: "14"
      check "Terms"
      click_button "Sign Up"
    end

    expect(page).to have_selector('.flash.notice',
      text: "User created. A confirmation link has been emailed to you; use this to activate your account.",)
    expect(page).to have_current_path(root_path)
    assert_enqueued_emails 1

    within("#header-buttons-links") { click_link "Sign up" }
    click_link "Didn't get a confirmation email?"
    fill_in "Email", with: "not an email"
    click_button "Resend confirmation instructions"
    expect(page).to have_selector(".flash.notice", text: "A confirmation link has been emailed to you.")
    assert_enqueued_emails 1 # no extra email should be sent

    click_link "Didn't get a confirmation email?"
    fill_in "Email", with: "wrong" + new_user_email
    click_button "Resend confirmation instructions"
    expect(page).to have_selector(".flash.notice", text: "A confirmation link has been emailed to you.")
    assert_enqueued_emails 1 # no extra email should be sent

    click_link "Didn't get a confirmation email?"
    fill_in "Email", with: new_user_email
    click_button "Resend confirmation instructions"
    expect(page).to have_selector(".flash.notice", text: "A confirmation link has been emailed to you.")
    assert_enqueued_emails 2

    mail_args = deserialize_enqueued_mail(mail_queue.last)
    token = mail_args[-1][:args][1]
    visit user_confirmation_path(confirmation_token: token)
    expect(page).to have_current_path(new_user_session_path)
    expect(page).to have_selector('.flash.notice', text: "Email address confirmed.")
  end
end
