RSpec.describe "Editing user profile" do
  let(:user) { create(:user, username: 'John Doe', email: 'dummy@example.com') }

  scenario "Logged-out user tries to edit a user", :aggregate_failures do
    visit profile_edit_user_path(user)
    expect(page).to have_selector('.error', text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
  end

  scenario "User tries to edit a different user", :aggregate_failures do
    login
    visit profile_edit_user_path(user)
    expect(page).to have_selector('.error', text: 'You do not have permission to modify this account.')
    expect(page).to have_current_path(continuities_path)
  end

  scenario "User edits themself", :js do
    login(user)

    # Page exists
    visit profile_edit_user_path(user)

    aggregate_failures do
      expect(page).to have_selector('.content-header', exact_text: 'Edit profile')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_field('user_profile', with: '')
      expect(page).to have_field('user_moiety_name', with: '')
      expect(page).to have_field('user_moiety', with: '')
      expect(page).to have_no_selector('.select2-selection__choice')
    end

    # Profile description field exists and can be filled
    fill_in 'user_profile', with: 'User Description'
    find_by_id("rtf").click

    # Moiety fields exist and can be filled
    fill_in 'user_moiety_name', with: 'Red'
    fill_in 'user_moiety', with: 'FF0000'

    # Content warnings exist and can be filled
    find('.select2-search__field').click
    find('.select2-search__field').set("warning 1")
    find('li', exact_text: 'warning 1').click

    expect(page).to have_selector('.select2-selection__choice', exact_text: '×warning 1')

    click_button 'Save'
    find('.flash.error summary').click

    # Everything has the correct values

    aggregate_failures do
      expect(page).to have_text("Red")
      expect(page).to have_text("User Description")
      moiety = find('.user-moiety span')
      expect(moiety).to be_present
      expect(moiety[:style]).to eq('cursor: default; color: rgb(255, 0, 0);')

      warn_msg = "This author has set some general content warnings which might apply to their posts even when not otherwise warned.\nwarning 1"
      expect(page).to have_selector('.flash.error', exact_text: warn_msg)
    end

    # Warning Select2 is showing the correct values
    visit profile_edit_user_path(user)
    expect(page).to have_selector('.select2-selection__choice', exact_text: '×warning 1')

    # Editing the user settings does not erase any of the profile fields
    visit edit_user_path(user)
    fill_in 'user_username', with: "Updated Username"
    within("#edit_user_#{user.id}") { click_button 'Save' }

    expect(find_by_id('user_username').value).to eq("Updated Username")

    visit user_path(user)
    find('.flash.error summary').click

    aggregate_failures do
      expect(page).to have_selector('.flash.error', text: 'warning 1')
      expect(page).to have_text("Red")
      expect(page).to have_text("User Description")
      moiety = find('.user-moiety span')
      expect(moiety).to be_present
      expect(moiety[:style]).to eq('cursor: default; color: rgb(255, 0, 0);')
    end
  end
end
