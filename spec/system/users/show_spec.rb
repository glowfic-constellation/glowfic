RSpec.describe "Viewing users" do
  let(:user) { create(:user) }

  scenario "Interacting with author warnings" do
    visit user_path(user)

    aggregate_failures do
      expect(page).to have_selector('.info-box-header', text: user.username)
      expect(page).to have_no_selector('.flash.error')
    end

    user.update!(content_warnings: [create(:content_warning, name: 'nsfw')])
    visit user_path(user)

    warn_msg = "This author has set some general content warnings which might apply to their posts even when not otherwise warned.\nnsfw"
    expect(page).to have_selector('.flash.error', exact_text: warn_msg)
  end

  context "without profile description" do
    scenario "shows own empty profile", :aggregate_failures do
      login(user)
      visit user_path(user)
      expect(page).to have_text("Author Profile")
      expect(page).to have_text("(Your profile is empty.)")
      expect(page).to have_link(href: profile_edit_user_path(user))
    end

    scenario "doesn't show other user's empty profile", :aggregate_failures do
      visit user_path(user)
      expect(page).to have_selector('.info-box-header', text: user.username)
      expect(page).to have_no_text("Author Profile")
      expect(page).to have_no_link(href: profile_edit_user_path(user))
    end
  end

  context "with profile description", :aggregate_failures do
    before(:each) { user.update!(profile: "User Description") }

    scenario "shows own profile" do
      login(user)
      visit user_path(user)
      expect(page).to have_text("User Description")
      expect(page).to have_link(href: profile_edit_user_path(user))
    end

    scenario "shows other user's profile" do
      visit user_path(user)
      expect(page).to have_text("Author Profile")
      expect(page).to have_text("User Description")
      expect(page).to have_no_link(href: profile_edit_user_path(user))
    end
  end

  scenario "has working Bookmarks link", :aggregate_failures do
    visit user_path(user)
    within(".user-info-box") { click_link("Bookmarks") }
    expect(page).to have_current_path(search_bookmarks_path(commit: "Search", user_id: user.id))
    expect(find('#user_id option[selected]')[:value]).to eq(user.id.to_s)
  end

  # TODO shows recent posts?
end
