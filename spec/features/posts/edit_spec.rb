require "spec_helper"

RSpec.feature "Editing posts", :type => :feature do
  scenario "Logged-out user tries to edit a post" do
    post = create(:post, subject: 'test subject')

    visit post_path(post)
    expect(page).to have_selector('#post-title', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      expect(page).to have_no_link('Edit')
    end

    visit edit_post_path(post)
    expect(page).to have_selector('.error', text: 'You must be logged in to view that page.')
    expect(page).to have_current_path(root_path)
    expect(page).to have_no_selector('#post-editor')
  end

  scenario "User edits a post" do
    user = create(:user, password: 'known')
    post = create(:post, user: user, subject: 'test subject')

    login(user, 'known')

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      click_button 'Save'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'other subject')
  end

  scenario "User edits a post with preview" do
    user = create(:user, password: 'known')
    post = create(:post, user: user, subject: 'test subject')

    login(user, 'known')

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      click_button 'Preview'
    end

    # verify preview, change again
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', text: 'other subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'other subject')
      fill_in 'Subject', with: 'third subject'
      click_button 'Save'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'third subject')
  end

  scenario "User tries to edit someone else's post" do
    post = create(:post, subject: 'test subject')

    login
    visit post_path(post)
    expect(page).to have_selector('#post-title', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      expect(page).to have_no_link('Edit')
    end

    visit edit_post_path(post)
    expect(page).to have_selector('.error', text: 'You do not have permission to modify this post.')
    expect(page).to have_current_path(post_path(post))
  end

  scenario "Moderator edits a post" do
    user = create(:user, password: 'known')
    post = create(:post, user: user, subject: 'test subject')

    login(create(:mod_user, password: 'known'), 'known')

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in 'Moderator note', with: 'example edit'
      click_button 'Save'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'other subject')
    within('.post-container') do
      # must not change post's user
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end
  end

  scenario "Moderator edits a post with preview" do
    user = create(:user, password: 'known')
    post = create(:post, user: user, subject: 'test subject')

    login(create(:mod_user, password: 'known'), 'known')

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    # first changes, then preview
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in 'Moderator note', with: 'example edit'
      click_button 'Preview'
    end

    # verify preview, change again
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', text: 'other subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'other subject')
      expect(page).to have_field('Moderator note', with: 'example edit')
      fill_in 'Subject', with: 'third subject'
      fill_in 'Moderator note', with: 'another edit'
      click_button 'Save'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'third subject')
  end
end
