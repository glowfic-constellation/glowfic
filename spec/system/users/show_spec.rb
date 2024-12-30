RSpec.describe "Viewing users" do
  let(:user) { create(:user, password: known_test_password) }

  scenario "Interacting with author warnings" do
    visit user_path(user)
    expect(page).to have_no_selector('.error')

    user.update!(content_warnings: [create(:content_warning, name: 'nsfw')])
    visit user_path(user)
    within('.error') do
      expect(page).to have_text("This author has set some general content warnings which might apply to their posts even when not otherwise warned")
      expect(page).to have_text('nsfw')
    end
  end

  context "without profile description" do
    scenario "shows own empty profile" do
      login(user, known_test_password)
      visit user_path(user)
      expect(page).to have_text("Author Profile")
      expect(page).to have_text("(Your profile is empty.)")
      expect(page).to have_link(href: profile_edit_user_path(user))
    end

    scenario "doesn't show other user's empty profile" do
      visit user_path(user)
      expect(page).to have_no_text("Author Profile")
      expect(page).to have_no_link(href: profile_edit_user_path(user))
    end
  end

  context "with profile description" do
    scenario "shows own profile" do
      user.update!(profile: "User Description")
      login(user, known_test_password)
      visit user_path(user)
      expect(page).to have_text("User Description")
      expect(page).to have_link(href: profile_edit_user_path(user))
    end

    scenario "shows other user's profile" do
      user.update!(profile: "User Description")
      visit user_path(user)
      expect(page).to have_text("Author Profile")
      expect(page).to have_text("User Description")
      expect(page).to have_no_link(href: profile_edit_user_path(user))
    end
  end

  scenario "has working Bookmarks link" do
    visit user_path(user)
    within(".user-info-box") { click_link("Bookmarks") }
    expect(page).to have_current_path(search_bookmarks_path(commit: "Search", user_id: user.id))
    expect(page).to have_selector("#user_id option[selected='selected'][value='#{user.id}']")
  end

  # TODO shows recent posts?
end
