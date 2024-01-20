RSpec.describe "Creating posts" do
  scenario "User creates a post", :js do
    visit new_post_path
    within(".error") { expect(page).to have_text("You must be logged in") }

    user = login
    create(:board)

    visit new_post_path
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector(".content-header", text: "Create a new post")

    click_button "Post"
    expect(page).to have_selector('.error', text: "Subject can't be blank")
    expect(page).to have_selector(".content-header", text: "Create a new post")

    click_button "HTML"
    fill_in "post_subject", with: "test subject"
    fill_in "post_content", with: "test content"
    click_button "Post"
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', exact_text: 'Post created.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'test subject')

    within('.post-content') do
      expect(page).to have_selector('p', exact_text: 'test content')
    end

    within('.post-container') do
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end
  end

  scenario "User creates a post with preview", :js do
    user = login
    create(:board)

    visit new_post_path
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector(".content-header", text: "Create a new post")

    fill_in "post_subject", with: "test subject"
    click_button "HTML"
    fill_in "post_content", with: "test content"
    click_button 'Preview'

    # verify preview, change
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_field('post_content', with: 'test content')
      fill_in 'Subject', with: 'other subject'
      fill_in "post_content", with: "other content"
    end
    click_button 'Post'

    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', exact_text: 'Post created.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'other subject')

    within('.post-content') do
      expect(page).to have_selector('p', exact_text: 'other content')
    end

    within('.post-container') do
      expect(page).to have_selector('.post-author', exact_text: user.username)
    end
  end

  scenario "User creates a post with a new NPC", :js do
    user = login
    create(:board)
    create(:character, user: user) # user must have at least 1 character to be able to pick a character

    visit new_post_path

    fill_in "post_subject", with: "test subject"
    page.find('img[title="Choose Character"]').click
    click_button 'NPC'
    page.find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
    page.find('.select2-container--open .select2-search__field').set('Adam')
    page.find('li', exact_text: 'Create New: Adam').click
    expect(page).to have_selector('#name', exact_text: 'Adam')
    click_button 'Preview'

    # verify preview, change
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_selector('#name', exact_text: 'Adam')
    end
    click_button 'Post'

    # post preserved NPC
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', exact_text: 'Post created.')
    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      expect(page).to have_text('Adam')
      click_link 'Adam'
    end

    expect(page).to have_text(/Adam\s+\(NPC\)/)
    expect(page).to have_text(/Original post.*test subject/)
  end

  scenario "User creates a post with an existing NPC", :js do
    user = login
    create(:board)
    create(:character, user: user) # user must have at least 1 character to be able to pick a character
    npc = create(:character, user: user, name: "Fred", nickname: "Another post", npc: true)

    visit new_post_path

    fill_in "post_subject", with: "test subject"
    page.find('img[title="Choose Character"]').click
    click_button 'NPC'
    page.find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
    page.find('li', exact_text: 'Fred | Another post').click
    expect(page).to have_selector('#name', exact_text: 'Fred')
    click_button 'Preview'

    # verify preview, change
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.content-header', exact_text: 'test subject')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_selector('#name', exact_text: 'Fred')
    end
    click_button 'Post'

    # post preserved NPC
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', exact_text: 'Post created.')
    expect(page).to have_selector('.post-container', count: 1)

    within('.post-container') do
      expect(page).to have_link('Fred', href: character_path(npc)) # should be the same Fred as before
    end
  end

  scenario "Fields are preserved on failed post#create", :js do
    login
    visit new_post_path
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector(".content-header", text: "Create a new post")

    fill_in "post_subject", with: "test subject"
    click_button "HTML"
    fill_in "post_content", with: "test content"
    click_button "Post"

    expect(page).to have_selector('.error', text: "Post could not be created because of the following problems:\nBoard must exist")
    expect(page).to have_selector('#post-editor')
    within('#post-editor') do
      expect(page).to have_selector('.view-button.selected', text: 'HTML')
      expect(page).to have_field('Subject', with: 'test subject')
      expect(page).to have_field('post_content', with: 'test content')
    end
  end

  scenario "User sees different editor settings" do
    user = login
    create(:board)

    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath(".//img[contains(@src, 'no-icon')]")
    end

    icon = create(:icon, user: user)
    user.update!(avatar: icon)
    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath(".//img[contains(@src, '#{icon.url}')]")
    end

    icon2 = create(:icon, user: user)
    character = create(:character, user: user, default_icon: icon2)
    user.update!(active_character: character)
    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath(".//img[contains(@src, '#{icon2.url}')]")
    end
  end

  scenario "Continuity settings show up", :js do
    login
    create(:board)
    board = create(:board)
    create(:board)
    create(:board_section, board: board, name: "Th<em> pirates")
    create(:board_section, board: board, name: "Th/ose/ aliens")

    visit new_post_path
    page.select(board.name, from: "Continuity:")
    expect(page).to have_select('Continuity section:')
    page.select("Th<em> pirates", from: "Continuity section:")
  end
end
