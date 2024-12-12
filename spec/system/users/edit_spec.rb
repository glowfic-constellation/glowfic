RSpec.describe "Editing user" do
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

    expect(page).to have_no_selector('.select2-selection__choice')
    page.find('.select2-search__field').click
    page.find('.select2-search__field').set("warning 1")
    page.find('li', exact_text: 'warning 1').click
    expect(page).to have_selector('.select2-selection__choice', exact_text: '×warning 1')
    within("#edit_user_#{user.id}") do
      click_button 'Save'
    end

    expect(page).to have_selector('.select2-selection__choice', exact_text: '×warning 1')

    page.find("[title='warning 1'] .select2-selection__choice__remove").click
    within("#edit_user_#{user.id}") do
      click_button 'Save'
    end
    expect(page).to have_no_selector('.select2-selection__choice')
  end
end
