RSpec.describe "Editing posts" do
  let(:user) { create(:user) }
  let(:mod) { create(:mod_user) }
  let(:post) { create(:post, user: user, subject: 'test subject', content: 'test content', editor_mode: 'html') }

  scenario "Logged-out user tries to edit a post" do
    visit post_path(post)
    expect(page).to have_selector('#post-title', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      expect(page).to have_no_link('Edit')
    end

    visit edit_post_path(post)
    expect(page).to have_selector('.flash.error', text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
    expect(page).to have_no_selector('#post-editor')
  end

  scenario "User edits a post" do
    login(user)

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_field('post_content', with: 'test content')

      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
    end
    click_button 'Save'

    expect(page).to have_selector('.flash.success', exact_text: 'Post updated.')
    expect(page).to have_no_selector('.error')

    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'other subject')
    expect(page).to have_selector('.post-content p', exact_text: 'other content')
  end

  scenario "User edits a post with preview" do
    login(user)

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
    end
    click_button 'Preview'

    # verify preview, change again
    expect(page).to have_selector('.content-header', exact_text: 'other subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'other subject')
      expect(page).to have_field('post_content', with: 'other content')

      fill_in 'Subject', with: 'third subject'
      fill_in "post_content", with: "third content"
    end
    click_button 'Save'

    expect(page).to have_selector('.flash.success', exact_text: 'Post updated.')
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'third subject')

    expect(page).to have_selector('.post-content p', exact_text: 'third content')
  end

  scenario "User tries to edit someone else's post" do
    login
    visit post_path(post)
    expect(page).to have_selector('#post-title', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      expect(page).to have_no_link('Edit')
    end

    visit edit_post_path(post)
    expect(page).to have_selector('.flash.error', text: 'You do not have permission to modify this post.')
    expect(page).to have_current_path(post_path(post))
  end

  scenario "Moderator edits a post" do
    login(mod)

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_field('post_content', with: 'test content')
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
      fill_in 'Moderator note', with: 'example edit'
    end
    click_button 'Save'

    expect(page).to have_selector('.flash.success', exact_text: 'Post updated.')
    expect(page).to have_no_selector('.flash.error')

    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'other subject')
    expect(page).to have_selector('.post-content p', exact_text: 'other content')
    expect(page).to have_selector('.post-container .post-author', exact_text: user.username) # must not change post's user
  end

  scenario "Moderator edits a post with preview" do
    login(mod)

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
      fill_in 'Moderator note', with: 'example edit'
    end
    click_button 'Preview'

    # verify preview, change again
    expect(page).to have_selector('.content-header', exact_text: 'other subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'other subject')
      expect(page).to have_field('Moderator note', with: 'example edit')
      fill_in 'Subject', with: 'third subject'
      fill_in "post_content", with: "third content"
      fill_in 'Moderator note', with: 'another edit'
    end
    click_button 'Save'

    expect(page).to have_selector('.flash.success', exact_text: 'Post updated.')
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'third subject')
    expect(page).to have_selector('.post-content p', exact_text: 'third content')
  end

  scenario "Moderator saves no change to a post in a board they can't write in" do
    other_user = create(:user)
    board = create(:board, creator: user, writers: [other_user], name: 'test board')
    post.update_columns(board_id: board.id) # rubocop:disable Rails/SkipsModelValidations -- avoid updating timestamps

    login(mod)

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    # first preview without changes
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_field('Continuity:', with: board.id)
    expect(page).to have_no_selector('.flash.error')
    click_button 'Preview'

    # verify preview, change again
    expect(page).to have_selector('.content-header', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_field('Continuity:', with: board.id)
    expect(page).to have_selector('#post-editor')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      fill_in 'Moderator note', with: 'test edit'
    end
    click_button 'Save'

    expect(page).to have_selector('.flash.success', exact_text: 'Post updated.')
    expect(page).to have_selector('.flash.breadcrumbs', exact_text: "Continuities » test board » test subject")
    expect(page).to have_no_selector('.flash.error')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_no_selector('.post-container .post-updated')
  end

  scenario "Fields are preserved on failed post#update" do
    login(user)

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_no_selector('.flash.error')

    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_field('post_content', with: 'test content')
      fill_in 'Subject', with: ''
      fill_in "Description", with: "test description"
      fill_in "post_content", with: "other content"
    end
    click_button 'Save'

    expect(page).to have_no_selector('.post-container')
    expect(page).to have_selector('.flash.error', text: "Subject can't be blank")

    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: '')
      expect(page).to have_field('Description', with: 'test description')
      expect(page).to have_field('post_content', with: 'other content')
    end
  end
end
