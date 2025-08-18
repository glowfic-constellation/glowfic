RSpec.describe "Searching bookmarks" do
  let!(:private_user) { create(:user) }
  let!(:public_user) { create(:user, public_bookmarks: true) }
  let!(:posts) { create_list(:post, 3) }
  let!(:replies) do
    posts.map do |post|
      create_list(:icon, 3).map do |icon|
        create(:reply, post: post, user: icon.user, icon: icon)
      end
    end.flatten
  end

  let!(:private_bookmarks) do
    marks = replies.values_at(1, 3).map { |reply| create(:bookmark, user: private_user, reply: reply) }
    marks2 = replies.values_at(4, 6).map.with_index { |reply, i| create(:bookmark, user: private_user, reply: reply, name: "Bookmark Name #{i}") }
    marks + marks2
  end

  let!(:public_bookmarks) do
    marks = replies.values_at(4, 5, 7, 8).map { |reply| create(:bookmark, user: public_user, reply: reply) }
    marks.prepend(create(:bookmark, user: public_user, reply: replies[2], name: "Bookmark Name 3"))
  end

  def perform_search(user: nil, posts: nil, condensed: nil, logged_in_user: nil)
    # Manually click the Select2 form fields
    if user.present?
      find_by_id("select2-user_id-container").click
      find(".select2-search__field[aria-controls='select2-user_id-results']").set(user.username)
      find("#select2-user_id-results li", text: user.username).click
    end

    if posts.present?
      posts.each do |post|
        find(".select2-selection.select2-selection--multiple").click
        find(".select2-search__field[aria-controls='select2-post_id-results']").set(post.subject)
        if post.visible_to?(logged_in_user)
          find("#select2-post_id-results li", text: post.subject).click
        else
          expect(page).to have_selector("#select2-post_id-results li", text: "No results found")
        end
      end
    end

    find_by_id("condensed").set(condensed)

    click_button 'Search'
    expect(page).to have_no_selector('.error')
  end

  def clear_posts_selection
    first(".select2-selection__choice__remove").click until all(".select2-selection__choice__remove", wait: false).empty?
  end

  def validate_bookmarks_found(bookmarks, posts, condensed: false)
    # Validate that the correct bookmarks were found
    # `bookmarks` may include bookmarks that are not in `posts` in which case they should not be on the page
    aggregate_failures do
      posts.each do |post|
        expect(page).to have_link(post.subject, href: post_path(post), count: 1)
      end

      num_results = 0
      bookmarks.each do |bookmark|
        unless posts.include?(bookmark.post)
          expect(page).to have_no_selector(".bookmark-name[data-bookmark-id='#{bookmark.id}']")
          expect(page).to have_no_link(href: post_path(bookmark.post))
          next
        end

        num_results += 1
        bookmark_name_div = find(".bookmark-name[data-bookmark-id='#{bookmark.id}']")
        if bookmark.name.present?
          expect(bookmark_name_div).to have_text(bookmark.name)
        else
          expect(bookmark_name_div).to have_text("(Unnamed)")
        end

        expect(page).to have_link(bookmark.reply.user.username, href: user_path(bookmark.reply.user))
        expect(page).to have_link(href: reply_path(bookmark.reply, anchor: "reply-#{bookmark.reply.id}"), count: 1)
        if condensed
          expect(page).to have_no_link(href: icon_path(bookmark.reply.icon))
        else
          expect(page).to have_link(bookmark.reply.keyword, href: icon_path(bookmark.reply.icon))
        end
      end

      expect(page).to have_text("#{num_results} results")
      expect(page).to have_selector('.paginator', text: "Total: #{num_results}")
    end
  end

  scenario "works", :js do
    visit search_bookmarks_path

    aggregate_failures do
      expect(page).to have_selector("#select2-user_id-container")
      expect(page).to have_selector(".select2-selection.select2-selection--multiple", count: 1)
    end

    # Empty search works and does not show results
    perform_search

    aggregate_failures do
      expect(page).to have_no_text("results")
      expect(page).to have_no_selector(".paginator")
    end

    # Searching for bookmarks without specifying a user does not show results
    perform_search posts: posts

    aggregate_failures do
      expect(page).to have_no_text("results")
      expect(page).to have_no_selector(".paginator")
    end

    clear_posts_selection

    # Searching for a private user's bookmarks should show zero results
    perform_search user: private_user

    aggregate_failures do
      expect(page).to have_no_selector(".bookmark-name")
      expect(page).to have_text("0 results")
      within(".paginator") { expect(page).to have_text("Total: 0") }
    end

    # Searching for a private user's public bookmarks shows results
    private_bookmarks.first.update!(public: true)
    private_bookmarks.last.update!(public: true)
    perform_search user: private_user

    validate_bookmarks_found [private_bookmarks.first, private_bookmarks.last], [private_bookmarks.first.post, private_bookmarks.last.post]

    private_bookmarks.first.update!(public: false)
    private_bookmarks.last.update!(public: false)

    # Searching for a public user's bookmarks does show results
    perform_search user: public_user
    validate_bookmarks_found public_bookmarks, posts

    # Searching for own bookmarks does show results
    login(private_user)
    visit search_bookmarks_path
    perform_search user: private_user, logged_in_user: private_user

    validate_bookmarks_found private_bookmarks, posts

    # Condensed search hides icons
    perform_search user: private_user, condensed: true, logged_in_user: private_user
    validate_bookmarks_found private_bookmarks, posts, condensed: true

    # Filtering posts works
    perform_search user: private_user, posts: [posts[0], posts[1]], logged_in_user: private_user
    validate_bookmarks_found private_bookmarks, [posts[0], posts[1]]
    clear_posts_selection

    # Private posts don't show up
    posts[0].update!(privacy: :private)
    perform_search user: private_user, posts: [posts[0], posts[1]], logged_in_user: private_user
    validate_bookmarks_found private_bookmarks, [posts[1]]
  end

  scenario "allows managing own bookmarks", :js do # rubocop:disable RSpec/MultipleExpectations
    login(private_user)
    visit search_bookmarks_path
    perform_search user: private_user

    # Can toggle bookmark name editor
    first_bookmark = private_bookmarks.first
    first_bookmark_name_text_field = find(".bookmark-name-text-field[data-bookmark-id='#{first_bookmark.id}']", visible: false)
    first_bookmark_edit_button = find(".edit-bookmark[data-bookmark-id='#{first_bookmark.id}']")

    expect(first_bookmark_name_text_field).not_to be_visible

    first_bookmark_edit_button.click

    expect(first_bookmark_name_text_field).to be_visible

    first_bookmark_edit_button.click

    expect(first_bookmark_name_text_field).not_to be_visible

    # Toggling one bookmark untoggles another
    last_bookmark = private_bookmarks.last
    last_bookmark_name_text_field = find(".bookmark-name-text-field[data-bookmark-id='#{last_bookmark.id}']", visible: false)
    last_bookmark_edit_button = find(".edit-bookmark[data-bookmark-id='#{last_bookmark.id}']")

    expect(last_bookmark_name_text_field).not_to be_visible

    last_bookmark_edit_button.click

    expect(last_bookmark_name_text_field).to be_visible

    first_bookmark_edit_button.click

    aggregate_failures do
      expect(first_bookmark_name_text_field).to be_visible
      expect(last_bookmark_name_text_field).not_to be_visible
    end

    first_bookmark_edit_button.click

    # Can rename bookmark
    first_bookmark_edit_button.click
    new_bookmark_name = "New Bookmark Name #{first_bookmark.id}"
    first_bookmark_name_text_field.set(new_bookmark_name)
    click_button "Save"

    aggregate_failures do
      expect(find('.saveconf')['data-bookmark-id']).to eq(first_bookmark.id.to_s)
      expect(first_bookmark_name_text_field).not_to be_visible
    end

    refresh

    expect(find(".bookmark-name[data-bookmark-id='#{first_bookmark.id}']")).to have_text(new_bookmark_name)

    # Can toggle bookmark publicness
    first_bookmark_edit_button.click
    first_bookmark_public_checkbox = find('.bookmark-public-checkbox')
    first_bookmark_public_checkbox.click
    click_button "Save"

    expect(find('.saveconf')['data-bookmark-id']).to eq(first_bookmark.id.to_s)

    refresh
    first_bookmark_edit_button.click

    expect(first_bookmark_public_checkbox).to be_checked

    first_bookmark_public_checkbox.click
    click_button "Save"

    # Discarding changes works
    first_bookmark_edit_button.click
    first_bookmark_name_text_field.set(new_bookmark_name + "different")
    first_bookmark_public_checkbox.click
    accept_alert { click_button "Discard Changes" }

    aggregate_failures do
      expect(first_bookmark_name_text_field.value).to eq(new_bookmark_name)
      expect(first_bookmark_public_checkbox).not_to be_checked
    end

    first_bookmark_edit_button.click

    # Can clear bookmark name
    first_bookmark_edit_button.click
    first_bookmark_name_text_field.set("")
    click_button "Save"

    expect(find(".bookmark-name[data-bookmark-id='#{first_bookmark.id}']")).to have_text("(Unnamed)")

    # Can remove bookmark from search page
    previous_path = current_url
    find("a[href='#{bookmark_path(last_bookmark)}'][data-method='delete']").click

    aggregate_failures do
      expect(page).to have_current_path(previous_path + "#reply-#{last_bookmark.reply.id}") # It redirects back with an anchor
      expect(page).to have_no_selector(".bookmark-name[data-bookmark-id='#{last_bookmark.id}']")
    end

    # Can copy another user's bookmark
    perform_search user: public_user
    new_bookmark = public_bookmarks.detect { |bookmark| bookmark.name.present? && !bookmark.reply.bookmarks.find_by(user_id: private_user.id) }
    click_link(href: bookmarks_path(at_id: new_bookmark.reply.id, name: new_bookmark.name.presence))
    perform_search user: private_user

    aggregate_failures do
      expect(page).to have_link(new_bookmark.reply.user.username, href: user_path(new_bookmark.reply.user))
      expect(page).to have_link(href: reply_path(new_bookmark.reply, anchor: "reply-#{new_bookmark.reply.id}"), count: 1)
      expect(page).to have_link(new_bookmark.reply.keyword, href: icon_path(new_bookmark.reply.icon))
      expect(page).to have_text(new_bookmark.name)
    end
  end

  # TODO paginates correctly
end
