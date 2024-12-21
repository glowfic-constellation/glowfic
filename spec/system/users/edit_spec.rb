RSpec.describe "Editing account settings" do
  let(:user) { create(:user, username: 'John Doe', password: 'known', email: 'dummy@example.com') }

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
    login(user, 'known')
    visit edit_user_path(user)
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.editor-title', exact_text: 'Account Settings')

    # TODO all fields
    # within("#edit_user_#{user.id}") do
    #   expect(page).to have_field('Username', with: 'John Doe')
    #   expect(page).to have_field('Email address', with: 'dummy@example.com')
    #   fill_in 'Username', with: 'Jane Doe'
    #   fill_in "Email address", with: "dummy2@example.com"
    # end
  end
end
