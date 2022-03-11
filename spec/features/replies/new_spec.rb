RSpec.feature "Creating replies", :type => :feature do
  scenario "User replies to own post" do
    user = login
    post = create(:post, user: user)

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_no_selector('.post-expander', text: 'Join Thread')
    expect(page).to have_selector('#post-editor')

    # preview first:
    within('#post-editor') do
      click_button 'Preview'
    end
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Draft saved!')
    expect(page).to have_selector('#post-editor')

    # then save:
    within('#post-editor') do
      click_button 'Post'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Posted!')
    expect(page).to have_selector('.post-container', count: 2)
    within('.post-reply') do
      expect(page).to have_selector('.post-author', exact_text: user.username)
      expect(page).to have_no_selector('.post-icon')
      expect(page).to have_no_selector('.post-character')
      expect(page).to have_no_selector('.post-screenname')
    end

    # check author list
    visit stats_post_path(post)
    within(row_for('Authors')) do
      expect(page).to have_selector('a', count: 1)
      expect(page).to have_link(exact_text: user.username, href: user_path(user))
    end
  end

  scenario "User replies to open post" do
    post = create(:post)

    user = login
    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('.post-expander', text: 'Join Thread')
    expect(page).to have_selector('.hidden #post-editor')

    # TODO: use javascript to expand post editor
    within('#post-editor') do
      click_button 'Post'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Posted!')
    expect(page).to have_selector('.post-container', count: 2)
    within('.post-reply') do
      expect(page).to have_selector('.post-author', exact_text: user.username)
      expect(page).to have_no_selector('.post-icon')
      expect(page).to have_no_selector('.post-character')
      expect(page).to have_no_selector('.post-screenname')
    end

    # check author list
    visit stats_post_path(post)
    within(row_for('Authors')) do
      expect(page).to have_selector('a', count: 2)
      expect(page).to have_link(exact_text: post.user.username, href: user_path(post.user))
      expect(page).to have_link(exact_text: user.username, href: user_path(user))
    end
  end

  scenario "User interacts with javascript", js: true do
    post = create(:post)

    user = login
    icon = create(:icon, user: user, keyword: "<strong> icon")
    gallery = create(:gallery, user: user, name: "icons of the <strong>", icons: [icon])
    icon2 = create(:icon, user: user)
    gallery2 = create(:gallery, user: user, icons: [icon2])
    create(:character, user: user, name: "Alice")
    fred = create(:character, user: user, name: "Fred the <strong>!", galleries: [gallery, gallery2])
    create(:alias, character: fred, name: "Fred")
    create(:alias, character: fred, name: "The <strong>!")
    create(:character, user: user, name: "John")

    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    page.find(".post-expander", text: "+ Join Thread").click

    within('#post-editor') do
      page.find("#swap-character").click
      select "Fred the <strong>!", from: "active_character"

      page.find("#swap-alias").click
      select "The <strong>!", from: "character_alias"

      page.find("#current-icon-holder").click
      expect(page).to have_text("icons of the <strong>")
      within(page.find(".gallery-icon", text: "<strong> icon")) do
        page.find("img").click
      end

      page.find("#html").click

      fill_in id: "reply_content", with: "test reply!"
      click_on "Post"
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Posted!')
    expect(page).to have_selector('.post-container', count: 2)
    within('.post-reply') do
      expect(page).to have_text(user.username)
      expect(page).to have_text("test reply!")
      expect(page).to have_text("The <strong>!")
      expect(page.find(".post-icon img")[:alt]).to eq("<strong> icon")
    end
  end

  scenario "User tries to reply to locked post" do
    post = create(:post, authors_locked: true)

    login
    visit post_path(post)
    expect(page.text).not_to include('Join Thread')
    expect(page).to have_no_selector('#post-editor')
  end

  scenario "Logged-out user tries to reply to post" do
    post = create(:post)

    visit post_path(post)
    expect(page.text).not_to include('Join Thread')
    expect(page).to have_no_selector('#post-editor')
  end
end
