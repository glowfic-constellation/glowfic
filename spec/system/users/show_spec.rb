RSpec.describe "Viewing users" do
  let(:user) { create(:user) }

  scenario "without author warnings" do
    visit user_path(user)
    expect(page).to have_no_selector('.error')
  end

  scenario "with author warnings" do
    user.update!(content_warnings: [create(:content_warning, name: 'nsfw')])
    visit user_path(user)
    within('.error') do
      expect(page).to have_text("This author has set some general content warnings which might apply to their posts even when not otherwise warned")
      expect(page).to have_text('nsfw')
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
