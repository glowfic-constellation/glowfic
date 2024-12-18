RSpec.describe "Editing user profile" do
  let(:user) { create(:user, username: 'John Doe', password: 'known', email: 'dummy@example.com') }

  scenario "Logged-out user tries to edit a user" do
    visit profile_edit_user_path(user)
    expect(page).to have_selector('.error', text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
  end

  scenario "User tries to edit a different user" do
    login
    visit profile_edit_user_path(user)
    expect(page).to have_selector('.error', text: 'You do not have permission to modify this account.')
    expect(page).to have_current_path(continuities_path)
  end

  scenario "User edits themself", :js do
    login(user, 'known')
    visit profile_edit_user_path(user)
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit profile')

    expect(page).to have_field('user_profile', with: '')
    fill_in 'user_profile', with: 'User Description'
    page.find_by_id("rtf").click

    expect(page).to have_field('user_moiety_name', with: '')
    expect(page).to have_field('user_moiety', with: '')
    fill_in 'user_moiety_name', with: 'Red'
    fill_in 'user_moiety', with: 'FF0000'

    expect(page).to have_no_selector('.select2-selection__choice')
    page.find('.select2-search__field').click
    page.find('.select2-search__field').set("warning 1")
    page.find('li', exact_text: 'warning 1').click
    expect(page).to have_selector('.select2-selection__choice', exact_text: '×warning 1')

    click_button 'Save'
    within('.error') do
      expect(page).to have_text("This author has set some general content warnings which might apply to their posts even when not otherwise warned")
      page.find('summary').click
      expect(page).to have_text('warning 1')
    end
    expect(page).to have_text("Red")
    expect(page).to have_text("User Description")
    moiety = page.find('.user-moiety span')
    expect(moiety).to be_present
    expect(moiety[:style]).to eq('cursor: default; color: rgb(255, 0, 0);')

    visit profile_edit_user_path(user)
    expect(page).to have_selector('.select2-selection__choice', exact_text: '×warning 1')
  end
end
