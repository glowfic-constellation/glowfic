RSpec.describe "Creating replies" do
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
    expect(page).to have_selector('.success', exact_text: 'Draft saved.')
    expect(page).to have_selector('#post-editor')

    # then save:
    within('#post-editor') do
      click_button 'Post'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Reply posted.')
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

  scenario "User replies to open post", :js do
    post = create(:post)

    user = login
    visit post_path(post)
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('.post-expander', text: 'Join Thread')
    page.find(".post-expander", text: "+ Join Thread").click

    within('#post-editor') do
      click_button 'Post'
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Reply posted.')
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

  scenario "User interacts with javascript", :js do
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
      page.find('img[title="Choose Character"]').click
      select "Fred the <strong>!", from: "active_character"

      page.find('img[title="Choose Alias"]').click
      select "The <strong>!", from: "character_alias"

      page.find_by_id('current-icon-holder').click
      expect(page).to have_text("icons of the <strong>")
      page.find(:xpath, "//*[contains(@class,'gallery-icon')][contains(text(),'<strong> icon')]//img").click

      click_button "HTML"

      fill_in id: "reply_content", with: "test reply!"
      click_button "Post"
    end

    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', exact_text: 'Reply posted.')
    expect(page).to have_selector('.post-container', count: 2)
    within('.post-reply') do
      expect(page).to have_text(user.username)
      expect(page).to have_text("test reply!")
      expect(page).to have_text("The <strong>!")
      expect(page.find(".post-icon img")[:alt]).to eq("<strong> icon")
    end
  end

  scenario "User creates a reply with a new NPC", :js do
    setting = create(:setting, name: "Settingsverse")
    post = create(:post, subject: 'Sample post', settings: [setting])

    user = login
    create(:character, user: user) # user must have at least 1 character to be able to pick a character

    visit post_path(post)
    page.find('.post-expander', text: 'Join Thread').click
    page.find('img[title="Choose Character"]').click
    click_button 'NPC'
    page.find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
    page.find('.select2-container--open .select2-search__field').set('Jade')
    page.find('li', exact_text: 'Create New: Jade').click
    expect(page).to have_selector('#name', exact_text: 'Jade')
    click_button 'Preview'

    # verify preview, change
    expect(page).to have_no_selector('.error')
    expect(page).to have_text("Draft saved. Your new NPC character has also been persisted!")
    expect(page).to have_selector('.content-header', exact_text: 'Sample post')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_selector('#name', exact_text: 'Jade')
    end
    click_button 'Post'

    # reply uses NPC
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', exact_text: 'Reply posted.')
    expect(page).to have_selector('.post-reply', count: 1)

    within('.post-reply') do
      expect(page).to have_text('Jade')
      click_link 'Jade'
    end

    expect(page).to have_text(/Jade\s+\(NPC\)/)
    expect(page).to have_text(/Original post.*Sample post/)
    expect(page).to have_text(/Setting.*Settingsverse/)
  end

  scenario "User creates a reply with an existing NPC", :js do
    post = create(:post, subject: 'Sample post')

    user = login
    create(:character, user: user) # user must have at least 1 character to be able to pick a character
    npc = create(:character, user: user, name: "Janet", nickname: "Post number 1", npc: true)

    visit post_path(post)
    page.find('.post-expander', text: 'Join Thread').click
    page.find('img[title="Choose Character"]').click
    click_button 'NPC'
    page.find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
    page.find('li', exact_text: 'Janet | Post number 1').click
    expect(page).to have_selector('#name', exact_text: 'Janet')
    click_button 'Preview'

    # verify preview, change
    expect(page).to have_no_selector('.error')
    expect(page).to have_text("Draft saved.") # (no NPC created)
    expect(page).to have_selector('.content-header', exact_text: 'Sample post')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_selector('#name', exact_text: 'Janet')
    end
    click_button 'Post'

    # reply uses NPC
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', exact_text: 'Reply posted.')
    expect(page).to have_selector('.post-reply', count: 1)

    within('.post-reply') do
      expect(page).to have_link('Janet', href: character_path(npc)) # should be the same Janet as before
    end
  end

  scenario "User creates a reply with an alias", :js do
    post = create(:post)

    user = login
    char = create(:character, name: "Base Character", user: user)
    create(:alias, name: "Alias 1", character: char)
    create(:alias, name: "Alias 2", character: char)

    # select alias in UI
    visit post_path(post)
    page.find('.post-expander', text: 'Join Thread').click
    page.find('img[title="Choose Character"]').click
    page.find('#swap-character-character .select2-selection__rendered').click
    page.find('li', exact_text: 'Base Character').click
    expect(page).to have_selector('#name', exact_text: 'Base Character')
    page.find('img[title="Choose Alias"]').click
    page.find('.select2-selection__rendered', exact_text: "Base Character").click
    page.find('li', exact_text: 'Alias 2').click
    expect(page).to have_selector('#name', exact_text: 'Alias 2')
    click_button 'Preview'

    # verify preview
    expect(page).to have_no_selector('.error')
    expect(page).to have_text("Draft saved.")
    within('.post-reply') do
      expect(page).to have_selector('.post-character', exact_text: 'Alias 2')
    end
    within('#post-editor') do
      expect(page).to have_selector('#name', exact_text: 'Alias 2')
    end
    click_button 'Post'

    # reply uses alias
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', exact_text: 'Reply posted.')
    expect(page).to have_selector('.post-reply', count: 1)

    within('.post-reply') do
      expect(page).to have_link('Alias 2', href: character_path(char))
    end

    # new editor should have the same alias selected for continuity
    within('#post-editor') do
      expect(page).to have_selector('#name', exact_text: 'Alias 2')
      click_button "HTML"
      fill_in id: "reply_content", with: "test reply!"
    end
    click_button "Post"

    # and should save this alias correctly
    expect(page).to have_selector('.post-reply', count: 2)
    page.find_all(".post-reply").each do |reply|
      within(reply) do
        expect(page).to have_link('Alias 2', href: character_path(char))
      end
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
