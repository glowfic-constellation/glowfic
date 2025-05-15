RSpec.describe "Editing posts" do
  scenario "Logged-out user tries to edit a post" do
    post = create(:post, subject: 'test subject')

    visit post_path(post)

    aggregate_failures do
      expect(page).to have_selector('#post-title', exact_text: 'test subject')
      expect(page).to have_selector('.post-container', count: 1)
      within('.post-container') do
        expect(page).to have_no_link('Edit')
      end
    end

    visit edit_post_path(post)

    aggregate_failures do
      expect(page).to have_selector('.error', text: 'You must be logged in to view that page.')
      expect(page).to have_current_path(root_path)
      expect(page).to have_no_selector('#post-editor')
    end
  end

  scenario "User edits a post" do
    user = create(:user, password: known_test_password)
    post = create(:post, user: user, subject: 'test subject', content: 'test content', editor_mode: 'html')

    login(user, known_test_password)

    visit post_path(post)

    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      click_link 'Edit'
    end

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Edit post')
      expect(page).to have_no_selector('.post-container')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_field('post_content', with: 'test content')
      end
    end

    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
    end
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.success', exact_text: 'Post updated.')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-title', exact_text: 'other subject')

      within('.post-content') do
        expect(page).to have_selector('p', exact_text: 'other content')
      end
    end
  end

  scenario "User edits a post with preview" do
    user = create(:user, password: known_test_password)
    post = create(:post, user: user, subject: 'test subject', editor_mode: 'html')

    login(user, known_test_password)
    visit post_path(post)

    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      click_link 'Edit'
    end

    # first changes, then preview
    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Edit post')
      expect(page).to have_no_selector('.post-container')
    end

    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
    end
    click_button 'Preview'

    # verify preview, change again
    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'other subject')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-editor')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'other subject')
        expect(page).to have_field('post_content', with: 'other content')
      end
    end

    within('#post-editor') do
      fill_in 'Subject', with: 'third subject'
      fill_in "post_content", with: "third content"
    end
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.success', exact_text: 'Post updated.')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-title', exact_text: 'third subject')

      within('.post-content') do
        expect(page).to have_selector('p', exact_text: 'third content')
      end
    end
  end

  scenario "User tries to edit someone else's post" do
    post = create(:post, subject: 'test subject')

    login
    visit post_path(post)

    aggregate_failures do
      expect(page).to have_selector('#post-title', exact_text: 'test subject')
      expect(page).to have_selector('.post-container', count: 1)
      within('.post-container') do
        expect(page).to have_no_link('Edit')
      end
    end

    visit edit_post_path(post)

    aggregate_failures do
      expect(page).to have_selector('.error', text: 'You do not have permission to modify this post.')
      expect(page).to have_current_path(post_path(post))
    end
  end

  scenario "Moderator edits a post" do
    user = create(:user)
    post = create(:post, user: user, subject: 'test subject', content: 'test content', editor_mode: 'html')

    login(create(:mod_user, password: known_test_password), known_test_password)

    visit post_path(post)

    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      click_link 'Edit'
    end

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Edit post')
      expect(page).to have_no_selector('.post-container')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_field('post_content', with: 'test content')
      end
    end

    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
      fill_in 'Moderator note', with: 'example edit'
    end
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.success', exact_text: 'Post updated.')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-title', exact_text: 'other subject')

      within('.post-content') do
        expect(page).to have_selector('p', exact_text: 'other content')
      end

      within('.post-container') do
        # must not change post's user
        expect(page).to have_selector('.post-author', exact_text: user.username)
      end
    end
  end

  scenario "Moderator edits a post with preview" do
    user = create(:user)
    post = create(:post, user: user, subject: 'test subject', editor_mode: 'html')

    login(create(:mod_user, password: known_test_password), known_test_password)

    visit post_path(post)

    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      click_link 'Edit'
    end

    # first changes, then preview
    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Edit post')
      expect(page).to have_no_selector('.post-container')
    end

    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
      fill_in 'Moderator note', with: 'example edit'
    end
    click_button 'Preview'

    # verify preview, change again
    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'other subject')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-editor')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'other subject')
        expect(page).to have_field('Moderator note', with: 'example edit')
      end
    end

    within('#post-editor') do
      fill_in 'Subject', with: 'third subject'
      fill_in "post_content", with: "third content"
      fill_in 'Moderator note', with: 'another edit'
    end
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.success', exact_text: 'Post updated.')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-title', exact_text: 'third subject')

      within('.post-content') do
        expect(page).to have_selector('p', exact_text: 'third content')
      end
    end
  end

  scenario "Moderator saves no change to a post in a board they can't write in" do
    user = create(:user)
    other_user = create(:user)
    board = create(:board, creator: user, writers: [other_user], name: 'test board')
    post = create(:post, user: user, board: board, subject: 'test subject')

    login(create(:mod_user, password: known_test_password), known_test_password)

    visit post_path(post)

    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      click_link 'Edit'
    end

    # first preview without changes
    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Edit post')
      expect(page).to have_no_selector('.post-container')
      expect(page).to have_field('Continuity:', with: board.id)
    end
    click_button 'Preview'

    # verify preview, change again
    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'test subject')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_field('Continuity:', with: board.id)
      expect(page).to have_selector('#post-editor')
    end

    within('#post-editor') do
      fill_in 'Moderator note', with: 'test edit'
    end
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.success', exact_text: 'Post updated.')
      expect(page).to have_selector('.flash.breadcrumbs', exact_text: "Continuities » test board » test subject")
      expect(page).to have_selector('.post-container', count: 1)

      within('.post-container') do
        expect(page).to have_no_selector('.post-updated')
      end
    end
  end

  scenario "Fields are preserved on failed post#update" do
    user = login
    post = create(:post, user: user, subject: 'test subject', content: 'test content')

    visit post_path(post)

    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      click_link 'Edit'
    end

    aggregate_failures do
      expect(page).to have_no_selector('.error')
      expect(page).to have_selector('.content-header', exact_text: 'Edit post')
      expect(page).to have_no_selector('.post-container')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_field('post_content', with: 'test content')
      end
    end

    within('#post-editor') do
      fill_in 'Subject', with: ''
      fill_in "Description", with: "test description"
      fill_in "post_content", with: "other content"
    end
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_no_selector('.post-container')
      expect(page).to have_selector('.error', text: "Subject can't be blank")

      expect(page).to have_selector('#post-editor')
      within('#post-editor') do
        expect(page).to have_field('Subject', with: '')
        expect(page).to have_field('Description', with: 'test description')
        expect(page).to have_field('post_content', with: 'other content')
      end
    end
  end
end
