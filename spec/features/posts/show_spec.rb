require "spec_helper"

RSpec.feature "Viewing posts", :type => :feature do
  scenario "User views a post with layouts" do
    user = login
    post = create(:post, user: user)

    visit post_path(post)
    expect(page).to have_xpath("//img[contains(@src, 'menu-')]")

    user.update!(layout: 'starrydark', avatar: create(:icon, user: user))
    visit post_path(post)
    expect(page).to have_xpath("//img[contains(@src, 'menugray-')]")
  end

  scenario "with an archived author" do
    user = create(:user)
    post = create(:post, user: user)
    reply = create(:reply, post: post)
    create(:reply, post: post, user: user)
    user.archive
    visit post_path(post)

    within('.post-post') do
      expect(page).to have_selector('.post-author', exact_text: '(deleted user)')
    end
    replies = page.all('.post-reply')
    within(replies[0]) do
      expect(page).to have_selector('.post-author', exact_text: reply.user.username)
    end
    within(replies[1]) do
      expect(page).to have_selector('.post-author', exact_text: '(deleted user)')
    end
  end
end
