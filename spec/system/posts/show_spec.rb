RSpec.describe "Viewing posts" do
  include ActiveJob::TestHelper

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
      post1 = create(:post)
      visit post_path(post1)

      expect(page).to have_selector('.content-header', text: post1.subject)
      expect(page).to have_no_selector('.flash.error')

      visit post_path(create(:post, content_warnings: [post_warning]))
      within('.flash.error') do
        expect(page).to have_text('This post has the following content warnings')
        expect(page).to have_text('violence')
      end

      visit post_path(create(:post, user: author))
      within('.flash.error') do
        expect(page).to have_text("This post's authors have general content warnings that might apply to the current post")
        expect(page).to have_text('nsfw')
      end

      visit post_path(post_with_warnings)
      within('.flash.error') do
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
      expect(page).to have_selector('.content-header', text: post_with_warnings.subject)
      expect(page).to have_no_selector('.error')
    end

    scenario "when user ignores warnings" do
      visit post_path(post_with_warnings, ignore_warnings: true)
      expect(page).to have_selector('.content-header', text: post_with_warnings.subject)
      expect(page).to have_no_selector('.error')
    end
  end

  context "Interacting with bookmarks" do
    let!(:user) { create(:user, password: known_test_password) }
    let!(:post) { create(:post) }
    let!(:reply) { create(:reply, post: post) }
    let!(:bookmark) { create(:bookmark, reply: reply, user: user) }

    scenario "when logged out" do
      visit post_path(post)
      within('#post-menu-box') { expect(page).to have_no_text("Bookmarks") }
      expect(page).to have_no_link("Add Bookmark")
    end

    context "when logged in", :js do
      scenario "as user with bookmarks" do
        login(user, known_test_password)

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

  scenario "Splitting a post" do
    user = create(:user, password: known_test_password)
    post = create(:post, user: user)
    create_list(:reply, 5, post: post)

    visit post_path(post)
    within('#post-menu-box') { expect(page).to have_no_link("Split Post") }
    expect(page).to have_no_link("Split Post Here")

    login(user, known_test_password)
    visit post_path(post)
    expect(page).to have_selector('.content-header', text: post.subject)
    expect(page).to have_no_link("Split Post Here")
    within('#post-menu-box') { click_link("Split Post") }
    expect(page).to have_link("Split Post Here", count: 5)

    within('#post-menu-box') { click_link("Disable Split UI") }
    expect(page).to have_no_link("Split Post Here")
    within('#post-menu-box') { click_link("Split Post") }

    within('.flash.error') do
      expect(page).to have_text('You are in Split Post mode. Please click the scissors icon on the reply you wish to make the start of the new post.')
      exit_split_post_mode_button = find(".link-box.action-dismiss.float-right")
      expect(exit_split_post_mode_button.text).to eq("Exit Split Post mode")
      exit_split_post_mode_button.find(:xpath, "..").click # xpath gets parent
    end

    expect(page).to have_no_link("Split Post Here")
    within('#post-menu-box') { click_link("Split Post") }

    reply = post.replies[2]
    click_link("Split Post Here", href: "/posts/#{post.id}/split?reply_id=#{reply.id}")
    expect(page).to have_selector('.flash.error', exact_text: 'Post must be locked to current authors to be split.')
    visit edit_post_path(post)
    find_by_id("post_authors_locked").click
    click_button "Save"

    within('#post-menu-box') { click_link("Split Post") }
    click_link("Split Post Here", href: "/posts/#{post.id}/split?reply_id=#{reply.id}")
    expect(find_by_id("reply_id").value).to eq(reply.id.to_s)

    click_button "Preview"
    within('.error') { expect(page).to have_text("Subject must not be blank.") }
    click_button "Split"
    within('.error') { expect(page).to have_text("Subject must not be blank.") }
    fill_in "Reply Id", with: ""
    click_button "Split"
    within('.error') { expect(page).to have_text("Reply could not be found.") }

    within('#post-menu-box') { click_link("Split Post") }
    click_link("Split Post Here", href: "/posts/#{post.id}/split?reply_id=#{reply.id}")
    fill_in "Subject", with: "new post subject"
    click_button "Preview"
    expect(page).to have_text("Splitting #{post.subject} at reply id # #{reply.id}")
    within(".content-header") { expect(page).to have_text("new post subject") }
    within(".post-container.post-reply") { expect(page).to have_text(reply.content) }

    perform_enqueued_jobs do
      click_button "Split"
      within('.success') { expect(page).to have_text("Post will be split.") }
    end

    visit post_path(post)
    expect(page).to have_selector('.content-header', text: post.subject)
    expect(page).to have_no_text(reply.content)

    click_link("Unread")
    click_link("new post subject")
    within('.post-container.post-post') { expect(page).to have_text(reply.content) }
    expect(page).to have_selector(".post-content", count: 3)
  end

  scenario "Hidden reply buttons" do
    user = login
    post = create(:post, user: user)
    create_list(:reply, 3, post: post)
    create_list(:reply, 2, post: post, user: user)

    visit post_path(post)
    expect(page).to have_link("Add Bookmark", count: 5)
    expect(page).to have_link("Edit", count: 3)

    user.update!(default_hide_edit_delete_buttons: true)
    visit post_path(post)
    expect(page).to have_link("Add Bookmark", count: 5)
    expect(page).to have_no_link("Edit")
    within('#post-menu-box') { click_link "Show Hidden Reply Buttons" }
    expect(page).to have_link("Add Bookmark", count: 5)
    expect(page).to have_link("Edit", count: 3)
    within('#post-menu-box') { click_link "Hide Reply Buttons" }
    expect(page).to have_link("Add Bookmark", count: 5)
    expect(page).to have_no_link("Edit")

    user.update!(default_hide_add_bookmark_button: true)
    visit post_path(post)
    expect(page).to have_selector('.content-header', text: post.subject)
    expect(page).to have_no_link("Add Bookmark")
    expect(page).to have_no_link("Edit")

    within('#post-menu-box') { click_link "Show Hidden Reply Buttons" }
    expect(page).to have_link("Add Bookmark", count: 5)
    expect(page).to have_link("Edit", count: 3)

    within('#post-menu-box') { click_link "Hide Reply Buttons" }
    expect(page).to have_no_link("Add Bookmark")
    expect(page).to have_no_link("Edit")

    user.update!(default_hide_edit_delete_buttons: false)
    visit post_path(post)
    expect(page).to have_link("Edit", count: 3)
    expect(page).to have_no_link("Add Bookmark")

    within('#post-menu-box') { click_link "Show Hidden Reply Buttons" }
    expect(page).to have_link("Add Bookmark", count: 5)
    expect(page).to have_link("Edit", count: 3)

    within('#post-menu-box') { click_link "Hide Reply Buttons" }
    expect(page).to have_link("Edit", count: 3)
    expect(page).to have_no_link("Add Bookmark")
  end
end
