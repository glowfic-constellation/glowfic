RSpec.describe "Viewing posts" do
  scenario "with a user layout set" do
    user = login
    post = create(:post, user: user)

    visit post_path(post)
    expect(page.find('.icon-view')['src']).to eq('/assets/icons/menu.png')

    user.update!(layout: 'starrydark', avatar: create(:icon, user: user))
    visit post_path(post)
    expect(page.find('.icon-view')['src']).to eq('/assets/icons/menugray.png')
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

  context "with content warnings" do
    let(:author_warning) { create(:content_warning, name: 'nsfw') }
    let(:author) { create(:user, content_warnings: [author_warning]) }
    let(:post_warning) { create(:content_warning, name: 'violence') }
    let(:post_with_warnings) { create(:post, user: author, content_warnings: [post_warning]) }

    scenario "when user has content warnings turned on" do
      visit post_path(create(:post))
      expect(page).to have_no_selector('.error')

      visit post_path(create(:post, content_warnings: [post_warning]))
      within('.error') do
        expect(page).to have_text('This post has the following content warnings')
        expect(page).to have_text('violence')
      end

      visit post_path(create(:post, user: author))
      within('.error') do
        expect(page).to have_text("This post's authors have general content warnings that might apply to the current post")
        expect(page).to have_text('nsfw')
      end

      visit post_path(post_with_warnings)
      within('.error') do
        expect(page).to have_text('This post has the following content warnings')
        expect(page).to have_text('violence')
        expect(page).to have_text("This post's authors also have general content warnings that might apply to the current post")
        expect(page).to have_text('nsfw')
      end
    end

    scenario "when user has content warnings turned off" do
      user = login
      user.update!(hide_warnings: true)
      visit post_path(post_with_warnings)
      expect(page).to have_no_selector('.error')
    end

    scenario "when user ignores warnings" do
      visit post_path(post_with_warnings, ignore_warnings: true)
      expect(page).to have_no_selector('.error')
    end
  end
end
