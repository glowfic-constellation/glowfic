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

  scenario "User edits a post", js: true do
    user = create(:user, password: 'known', default_editor: 'html')

    board = create(:board, name: 'test board', coauthors: [user])
    create_list(:board, 2)
    section = create(:board_section, board: board, name: 'test section')
    create_list(:board_section, 3, board: board)

    setting1 = create(:setting, name: 'test setting 1')
    create_list(:setting, 2)
    setting2 = create(:setting, name: 'test setting 2')
    label = create(:label, name: 'test label')
    warning1 = create(:content_warning, name: 'test warning 1')
    warning2 = create(:content_warning, name: 'test warning 2')
    warning3 = create(:content_warning, name: 'test warning 3')
    create_list(:content_warning, 5)

    gallery = create(:gallery, user: user)
    icon1 = create(:icon, user: user, keyword: 'test icon 1', galleries: [gallery])
    icon2 = create(:icon, user: user, keyword: 'test icon 2', galleries: [gallery])
    default_icon = create(:icon, user: user, keyword: 'test default icon', galleries: [gallery])
    create_list(:icon, 5, user: user, galleries: [gallery])

    character = create(:character, user: user, name: 'test character', screenname: 'just_a_test',
      galleries: [gallery], default_icon: default_icon)
    create_list(:character, 3, user: user)
    calias = create(:alias, character: character, name: 'test alias')
    create(:alias, character: character)

    post = create(:post,
      user: user,
      subject: 'test subject',
      content: 'test content',
      board: board,
      section: section,
      settings: [setting1],
      content_warnings: [warning1, warning2],
      character: character,
      icon: icon1,
    )

    login(user, 'known')

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')

    within('#post_form') do
      expect(page).to have_select('Setting:', selected: 'test setting 1')
      select2('Setting', 'setting 2')

      within('#post-editor') do
        within('.post-info-box') do
          expect(page).to have_selector('#current-icon')
          expect(find('#current-icon')[:alt]).to eq('test icon 1')
          expect(page).to have_select('icon_dropdown', selected: 'test icon 1', with_options: ['test icon 2'])

          within('.post-character') do
            expect(page).to have_selector('#name', text: 'test character')
            expect(page).to have_selector('#swap-alias')
          end

          expect(page).to have_selector('.post-screenname', text: 'just_a_test')
          expect(page).to have_selector('.post-author', text: user.username)
          expect(page).to have_selector('#swap-character')

          find('#swap-alias').click
          expect(page).to have_selector('#alias-selector')
          page.select('test alias')
        end

        find('#current-icon-holder').click
        expect(page).to have_selector('#reply-icon-selector')
        within('#reply-icon-selector') do
          find("img[alt='test icon 2']").click
        end
        expect(page).to have_select('icon_dropdown', selected: 'test icon 2')

        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_field('post_content', with: 'test content')

        fill_in 'Subject', with: 'other subject'
        fill_in "post_content", with: "other content"
      end
    end
    click_button 'Save'

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'other subject')

    within('.post-content') do
      expect(page).to have_selector('p', exact_text: 'other content')
    end
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
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
    end
    click_button 'Preview'

    # verify preview, change again
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'other subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'other subject')
      expect(page).to have_field('post_content', with: 'other content')
      fill_in 'Subject', with: 'third subject'
      fill_in "post_content", with: "third content"
    end
    click_button 'Save'

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'third subject')

    within('.post-content') do
      expect(page).to have_selector('p', exact_text: 'third content')
    end
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
    user = create(:user)
    post = create(:post, user: user, subject: 'test subject', content: 'test content')

    login(create(:mod_user, password: 'known'), 'known')

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_field('post_content', with: 'test content')
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
      fill_in 'Moderator note', with: 'example edit'
    end
    click_button 'Save'

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
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

  scenario "Moderator edits a post with preview" do
    user = create(:user)
    post = create(:post, user: user, subject: 'test subject')

    login(create(:mod_user, password: 'known'), 'known')

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
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'other subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'other subject')
      expect(page).to have_field('Moderator note', with: 'example edit')
      fill_in 'Subject', with: 'third subject'
      fill_in "post_content", with: "third content"
      fill_in 'Moderator note', with: 'another edit'
    end
    click_button 'Save'

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'third subject')

    within('.post-content') do
      expect(page).to have_selector('p', exact_text: 'third content')
    end
  end

  scenario "Moderator saves no change to a post in a board they can't write in" do
    user = create(:user)
    other_user = create(:user)
    board = create(:board, creator: user, writers: [other_user], name: 'test board')
    post = create(:post, user: user, board: board, subject: 'test subject')

    login(create(:mod_user, password: 'known'), 'known')

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      click_link 'Edit'
    end

    # first preview without changes
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    expect(page).to have_field('Continuity:', with: board.id)
    click_button 'Preview'

    # verify preview, change again
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_field('Continuity:', with: board.id)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      fill_in 'Moderator note', with: 'test edit'
    end
    click_button 'Save'

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'has been updated.')
    expect(page).to have_selector('.flash.breadcrumbs', exact_text: "Continuities » test board » test subject")
    expect(page).to have_selector('.post-container', count: 1)
    within('.post-container') do
      expect(page).to have_no_selector('.post-updated')
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

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'Edit post')
    expect(page).to have_no_selector('.post-container')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_field('post_content', with: 'test content')
      fill_in 'Subject', with: ''
      fill_in "Description", with: "test description"
      fill_in "post_content", with: "other content"
    end
    click_button 'Save'

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
