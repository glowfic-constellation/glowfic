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
    let(:post) { create(:post, user: author, content_warnings: [post_warning]) }

    context "when user has content warnings turned on" do
      scenario "shows post warnings" do
        post = create(:post, content_warnings: [post_warning])
        visit post_path(post)
        within('.error') do
          expect(page).to have_text('This post has the following content warnings')
          expect(page).to have_text('violence')
        end
      end

      scenario "shows author warnings" do
        post = create(:post, user: author)
        visit post_path(post)
        within('.error') do
          expect(page).to have_text("This post's authors have general content warnings that might apply to the current post")
          expect(page).to have_text('nsfw')
        end
      end

      scenario "shows post and author warnings" do
        visit post_path(post)
        within('.error') do
          expect(page).to have_text('This post has the following content warnings')
          expect(page).to have_text('violence')
          expect(page).to have_text("This post's authors also have general content warnings that might apply to the current post")
          expect(page).to have_text('nsfw')
        end
      end
    end

    scenario "when user has content warnings turned off" do
      user = login
      user.update!(hide_warnings: true)
      visit post_path(post)
      expect(page).to have_no_selector('.error')
    end

    scenario "when user ignores warnings" do
      visit post_path(post, ignore_warnings: true)
      expect(page).to have_no_selector('.error')
    end
  end

  context "Interacting with bookmarks" do
    let!(:user) { create(:user, password: 'known') }
    let!(:post) { create(:post) }
    let!(:reply) { create(:reply, post: post) }
    let!(:bookmark) { create(:bookmark, reply: reply, post: post, user: user) }

    scenario "when logged out" do
      visit post_path(post)
      within('#post-menu-box') { expect(page).to have_no_text("Bookmarks") }
      expect(page).to have_no_link("Add Bookmark")
    end

    context "when logged in", :js do
      scenario "as user with bookmarks" do
        login(user, 'known')

        visit post_path(post)
        find_by_id("post-menu").click
        within('#post-menu-box') { click_link("View Bookmarks") }
        expect(page).to have_current_path(search_bookmarks_path(commit: "Search", post_id: [post.id], user_id: user.id))
        expect(page).to have_selector("#user_id option[selected='selected'][value='#{user.id}']")
        expect(page).to have_selector("#post_id option[selected='selected'][value='#{post.id}']")

        visit post_path(post)
        click_link("Remove Bookmark", href: "/bookmarks/#{bookmark.id}")
        expect(page).to have_current_path(post_path(post))
        expect(page).to have_link("Add Bookmark", href: "/bookmarks?at_id=#{reply.id}")
      end

      scenario "as user without bookmarks" do
        login

        visit post_path(post)
        find_by_id("post-menu").click
        within('#post-menu-box') { expect(page).to have_no_text("View Bookmarks") }

        visit post_path(post)
        click_link("Add Bookmark", href: "/bookmarks?at_id=#{reply.id}")
        expect(page).to have_current_path(post_path(post))
        within(".post-container:has(#reply-#{reply.id})") { expect(page).to have_link("Remove Bookmark") }
      end
    end
  end
end
