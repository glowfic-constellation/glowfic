require "spec_helper"

RSpec.feature "Viewing posts", :type => :feature do
  scenario "User views a post with layouts" do
    user = login
    post = create(:post, user: user)

    visit post_path(post)
    expect(page).to have_xpath("//img[contains(@src, 'menu-')]")

    user.update_attributes(layout: 'starrydark', avatar: create(:icon, user: user))
    visit post_path(post)
    expect(page).to have_xpath("//img[contains(@src, 'menugray-')]")
  end
end
