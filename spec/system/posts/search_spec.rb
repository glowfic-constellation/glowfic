RSpec.describe "Searching posts" do
  scenario "does not show hide_ignored checkbox for users without hide_from_all" do
    user = create(:user, hide_from_all: false)
    login(user)

    visit search_posts_path
    expect(page).to have_button('Search') # page loaded
    expect(page).to have_no_field('hide_ignored')
    expect(page).to have_no_text('Hide ignored posts')
  end

  scenario "shows hide_ignored checkbox for users with hide_from_all" do
    user = create(:user, hide_from_all: true)
    login(user)

    visit search_posts_path
    expect(page).to have_field('hide_ignored')
    expect(page).to have_text('Hide ignored posts')
    expect(page).to have_checked_field('hide_ignored')
  end

  scenario "hide_ignored checkbox filters ignored posts when checked" do
    user = create(:user, hide_from_all: true)
    ignored_post = create(:post, subject: 'Ignored post')
    create(:post, subject: 'Normal post') # not ignored
    ignored_post.ignore(user)

    login(user)
    visit search_posts_path

    # Search with checkbox checked (default) - should hide ignored post
    click_button 'Search'
    within('#search_results') do
      expect(page).to have_selector('.post-subject', text: 'Normal post')
      expect(page).to have_no_selector('.post-subject', text: 'Ignored post')
    end

    # Uncheck the checkbox and search again - should show ignored post
    uncheck 'hide_ignored'
    click_button 'Search'
    within('#search_results') do
      expect(page).to have_selector('.post-subject', text: 'Normal post')
      expect(page).to have_selector('.post-subject', text: 'Ignored post')
    end
  end

  scenario "Searching a mixture of posts" do
    post = create(:post, subject: 'First post')

    visit search_posts_path

    def perform_search
      within('.search-form') do
        fill_in 'Subject', with: 'post'
      end
      click_button 'Search'

      expect(page).to have_selector('.search-params-header', text: /Search Posts - \d+ results/)
      expect(page).to have_no_selector('.flash.error')
    end

    # check post shows when public
    perform_search
    expect(page).to have_selector('#search_results .post-subject', text: 'First post')

    # check the post is hidden when private
    post.update!(privacy: :private)
    perform_search
    expect(page).to have_no_selector('#search_results .post-subject')

    # check the post is still hidden when there are two pages of results
    2.upto(26) { |i| create(:post, subject: 'post ' + i.to_s, privacy: :private) }
    perform_search
    expect(page).to have_no_selector('#search_results .post-subject')

    # check a new post shows up
    create(:post, subject: 'Last post') # post2
    perform_search
    within('#search_results') do
      expect(page).to have_selector('.post-subject', count: 1)
      expect(page).to have_selector('.post-subject', text: 'Last post')
    end
  end
end
