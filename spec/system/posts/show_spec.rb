RSpec.describe "Viewing posts" do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }

  scenario "with a user layout set" do
    login(user)

    visit post_path(post)
    expect(find('.icon-view')[:src]).to eq('/assets/icons/menu.png')

    user.update!(layout: 'starrydark', avatar: create(:icon, user: user))
    visit post_path(post)
    expect(find('.icon-view')[:src]).to eq('/assets/icons/menugray.png')
  end

  scenario "with an archived author", :aggregate_failures do
    reply = create(:reply, post: post)
    create(:reply, post: post, user: user)
    user.archive
    visit post_path(post)

    expect(page).to have_selector('.post-post .post-author', exact_text: '(deleted user)')

    replies = all('.post-reply')

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

      aggregate_failures do
        expect(page).to have_selector('.content-header', text: post1.subject)
        expect(page).to have_no_selector('.flash.error')
      end

      visit post_path(create(:post, content_warnings: [post_warning]))

      warn_msg1 = <<~MSG.chomp
        Dismiss all content warnings
        This post has the following content warnings:
        violence
      MSG
      expect(page).to have_selector('.flash.error', exact_text: warn_msg1)

      visit post_path(create(:post, user: author))

      warn_msg2 = <<~MSG.chomp
        Dismiss all content warnings
        This post's authors have general content warnings that might apply to the current post.
        #{author.username}
        nsfw
      MSG
      expect(page).to have_selector('.flash.error', exact_text: warn_msg2)

      visit post_path(post_with_warnings)

      warn_msg3 = <<~MSG.chomp
        Dismiss all content warnings
        This post has the following content warnings:
        violence
        This post's authors also have general content warnings that might apply to the current post.
        #{author.username}
        nsfw
      MSG
      expect(page).to have_selector('.flash.error', exact_text: warn_msg3)
    end

    scenario "when user has content warnings turned off", :aggregate_failures do
      user = login
      user.update!(hide_warnings: true)
      visit post_path(post_with_warnings)
      expect(page).to have_selector('.content-header', text: post_with_warnings.subject)
      expect(page).to have_no_selector('.flash.error')
    end

    scenario "when user ignores warnings", :aggregate_failures do
      visit post_path(post_with_warnings, ignore_warnings: true)
      expect(page).to have_selector('.content-header', text: post_with_warnings.subject)
      expect(page).to have_no_selector('.flash.error')
    end
  end

  context "Interacting with bookmarks" do
    let!(:post) { create(:post) }
    let!(:reply) { create(:reply, post: post) }
    let!(:bookmark) { create(:bookmark, reply: reply, user: user) }

    scenario "when logged out", :aggregate_failures do
      visit post_path(post)
      within('#post-menu-box') { expect(page).to have_no_text("Bookmarks") }
      expect(page).to have_no_link("Add Bookmark")
    end

    context "when logged in", :js do
      scenario "as user with bookmarks" do
        login(user)

        visit post_path(post)
        find_by_id("post-menu").click
        within('#post-menu-box') { click_link("View Bookmarks") }

        aggregate_failures do
          expect(page).to have_current_path(search_bookmarks_path(commit: "Search", post_id: [post.id], user_id: user.id))
          expect(find('#user_id option[selected]')[:value]).to eq(user.id.to_s)
          expect(find('#post_id option[selected]')[:value]).to eq(post.id.to_s)
        end

        visit post_path(post)
        click_link("Remove Bookmark", href: "/bookmarks/#{bookmark.id}")

        aggregate_failures do
          expect(page).to have_current_path(post_path(post))
          expect(page).to have_link("Add Bookmark", href: "/bookmarks?at_id=#{reply.id}")
        end
      end

      scenario "as user without bookmarks" do
        login

        visit post_path(post)
        find_by_id("post-menu").click

        within('#post-menu-box') { expect(page).to have_no_text("View Bookmarks") }

        visit post_path(post)
        click_link("Add Bookmark", href: "/bookmarks?at_id=#{reply.id}")

        aggregate_failures do
          expect(page).to have_current_path(post_path(post))
          within(".post-container:has(#reply-#{reply.id})") { expect(page).to have_link("Remove Bookmark") }
        end
      end
    end
  end

  scenario "Splitting a post" do # rubocop:disable RSpec/MultipleExpectations
    create_list(:reply, 5, post: post)

    visit post_path(post)
    within('#post-menu-box') { expect(page).to have_no_link("Split Post") }
    expect(page).to have_no_link("Split Post Here")

    login(user)
    visit post_path(post)

    aggregate_failures do
      expect(page).to have_selector('.content-header', text: post.subject)
      expect(page).to have_no_link("Split Post Here")
    end

    within('#post-menu-box') { click_link("Split Post") }
    expect(page).to have_link("Split Post Here", count: 5)

    within('#post-menu-box') { click_link("Disable Split UI") }
    expect(page).to have_no_link("Split Post Here")

    within('#post-menu-box') { click_link("Split Post") }

    within('.flash.error') do
      expect(page).to have_text('You are in Split Post mode. Please click the scissors icon on the reply you wish to make the start of the new post.')

      exit_split_post_mode_button = find(".link-box.action-dismiss")
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

    expect(page).to have_selector('.flash.error', exact_text: "Subject must not be blank.")
    click_button "Split"

    expect(page).to have_selector('.flash.error', exact_text: "Subject must not be blank.")

    fill_in "Reply Id", with: ""
    click_button "Split"

    expect(page).to have_selector('.flash.error', exact_text: "Reply could not be found.")

    within('#post-menu-box') { click_link("Split Post") }
    click_link("Split Post Here", href: "/posts/#{post.id}/split?reply_id=#{reply.id}")

    fill_in "Subject", with: "new post subject"
    click_button "Preview"

    aggregate_failures do
      expect(page).to have_text("Splitting #{post.subject} at reply id # #{reply.id}")
      expect(page).to have_selector('.content-header', exact_text: 'new post subject')
      expect(page).to have_selector('.post-container.post-reply', text: reply.content)
    end

    perform_enqueued_jobs { click_button "Split" }
    expect(page).to have_selector('.flash.success', exact_text: "Post will be split.")

    visit post_path(post)

    aggregate_failures do
      expect(page).to have_selector('.content-header', text: post.subject)
      expect(page).to have_no_text(reply.content)
    end

    click_link("Unread")
    click_link("new post subject")

    aggregate_failures do
      expect(page).to have_selector('.post-container.post-post', text: reply.content)
      expect(page).to have_selector(".post-content", count: 3)
    end
  end

  scenario "Hidden reply buttons" do # rubocop:disable RSpec/MultipleExpectations
    login(user)
    create_list(:reply, 3, post: post)
    create_list(:reply, 2, post: post, user: user)

    visit post_path(post)

    aggregate_failures do
      expect(page).to have_link("Add Bookmark", count: 5)
      expect(page).to have_link("Edit", count: 3)
    end

    user.update!(default_hide_edit_delete_buttons: true)
    visit post_path(post)

    aggregate_failures do
      expect(page).to have_link("Add Bookmark", count: 5)
      expect(page).to have_no_link("Edit")
    end

    within('#post-menu-box') { click_link "Show Hidden Reply Buttons" }

    aggregate_failures do
      expect(page).to have_link("Add Bookmark", count: 5)
      expect(page).to have_link("Edit", count: 3)
    end

    within('#post-menu-box') { click_link "Hide Reply Buttons" }

    aggregate_failures do
      expect(page).to have_link("Add Bookmark", count: 5)
      expect(page).to have_no_link("Edit")
    end

    user.update!(default_hide_add_bookmark_button: true)
    visit post_path(post)

    aggregate_failures do
      expect(page).to have_selector('.content-header', text: post.subject)
      expect(page).to have_no_link("Add Bookmark")
      expect(page).to have_no_link("Edit")
    end

    within('#post-menu-box') { click_link "Show Hidden Reply Buttons" }

    aggregate_failures do
      expect(page).to have_link("Add Bookmark", count: 5)
      expect(page).to have_link("Edit", count: 3)
    end

    within('#post-menu-box') { click_link "Hide Reply Buttons" }

    aggregate_failures do
      expect(page).to have_selector('.content-header', text: post.subject)
      expect(page).to have_no_link("Add Bookmark")
      expect(page).to have_no_link("Edit")
    end

    user.update!(default_hide_edit_delete_buttons: false)
    visit post_path(post)

    aggregate_failures do
      expect(page).to have_link("Edit", count: 3)
      expect(page).to have_no_link("Add Bookmark")
    end

    within('#post-menu-box') { click_link "Show Hidden Reply Buttons" }

    aggregate_failures do
      expect(page).to have_link("Add Bookmark", count: 5)
      expect(page).to have_link("Edit", count: 3)
    end

    within('#post-menu-box') { click_link "Hide Reply Buttons" }

    aggregate_failures do
      expect(page).to have_link("Edit", count: 3)
      expect(page).to have_no_link("Add Bookmark")
    end
  end
end
