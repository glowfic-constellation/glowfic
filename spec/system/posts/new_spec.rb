RSpec.describe "Creating posts" do
  before(:each) { create(:board) }

  scenario "User creates a post", :js do
    visit new_post_path

    expect(page).to have_selector('.flash.error', exact_text: 'You must be logged in to view that page.')

    user = login

    visit new_post_path

    aggregate_failures do
      expect(page).to have_selector(".content-header", text: "Create a new post")
      expect(page).to have_no_selector(".flash.error")
    end

    click_button "Post"

    aggregate_failures do
      expect(page).to have_selector('.flash.error', text: "Subject can't be blank")
      expect(page).to have_selector(".content-header", text: "Create a new post")
    end

    click_button 'HTML'
    fill_in 'Subject', with: 'test subject'
    fill_in 'post_content', with: 'test content'
    click_button 'Post'

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Post created.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-title', exact_text: 'test subject')
      expect(page).to have_selector('.post-content p', exact_text: 'test content')
      expect(page).to have_selector('.post-container .post-author', exact_text: user.username)
    end
  end

  scenario "User creates a post with preview", :js do
    user = login

    visit new_post_path

    aggregate_failures do
      expect(page).to have_selector(".content-header", text: "Create a new post")
      expect(page).to have_no_selector('.flash.error')
    end

    click_button 'HTML'
    fill_in 'Subject', with: 'test subject'
    fill_in 'post_content', with: 'test content'
    click_button 'Preview'

    # verify preview, change
    aggregate_failures do
      expect(page).to have_selector('.content-header', exact_text: 'test subject')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-editor')
      expect(page).to have_no_selector('.flash.error')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_field('post_content', with: 'test content')
      end
    end

    within('#post-editor') do
      fill_in 'Subject', with: 'other subject'
      fill_in 'post_content', with: 'other content'
    end
    click_button 'Post'

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Post created.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-title', exact_text: 'other subject')
      expect(page).to have_selector('.post-content p', exact_text: 'other content')
      expect(page).to have_selector('.post-container .post-author', exact_text: user.username)
    end
  end

  scenario "User creates a post with a new NPC", :js do
    user = login
    create(:character, user: user) # user must have at least 1 character to be able to pick a character

    visit new_post_path

    fill_in 'Subject', with: 'test subject'
    find('img[title="Choose Character"]').click
    click_button 'NPC'
    find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
    find('.select2-container--open .select2-search__field').set('Adam')
    find('li', exact_text: 'Create New: Adam').click

    expect(page).to have_selector('#name', exact_text: 'Adam')

    click_button 'Preview'

    # verify preview
    aggregate_failures do
      expect(page).to have_selector('.content-header', exact_text: 'test subject')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-editor')
      expect(page).to have_no_selector('.flash.error')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_selector('#name', exact_text: 'Adam')
      end
    end

    click_button 'Post'

    # post preserved NPC
    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Post created.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('.post-container', text: 'Adam')
    end

    within('.post-container') do
      click_link 'Adam'
    end

    aggregate_failures do
      expect(page).to have_selector('.info-box-header', exact_text: "Adam\n(NPC)")
      expect(page).to have_text(/Original post.*test subject/)
    end
  end

  scenario "User creates a post with an existing NPC", :js do
    user = login
    create(:character, user: user) # user must have at least 1 character to be able to pick a character
    npc = create(:character, user: user, name: "Fred", nickname: "Another post", npc: true)

    visit new_post_path

    fill_in 'Subject', with: 'test subject'
    find('img[title="Choose Character"]').click
    click_button 'NPC'
    find('.select2-selection__rendered', exact_text: 'Select NPC or type to create').click
    find('li', exact_text: 'Fred | Another post').click
    expect(page).to have_selector('#name', exact_text: 'Fred')
    click_button 'Preview'

    # verify preview
    aggregate_failures do
      expect(page).to have_selector('.content-header', exact_text: 'test subject')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_selector('#post-editor')
      expect(page).to have_no_selector('.flash.error')

      within('#post-editor') do
        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_selector('#name', exact_text: 'Fred')
      end
    end

    click_button 'Post'

    # post preserved NPC
    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Post created.')
      expect(page).to have_selector('.post-container', count: 1)
      expect(page).to have_no_selector('.flash.error')

      within('.post-container') do
        expect(page).to have_link('Fred', href: character_path(npc)) # should be the same Fred as before
      end
    end
  end

  scenario "Fields are preserved on failed post#create", :js do
    Board.delete_all
    login
    visit new_post_path

    aggregate_failures do
      expect(page).to have_selector(".content-header", text: "Create a new post")
      expect(page).to have_no_selector('.flash.error')
    end

    click_button 'HTML'
    fill_in 'Subject', with: 'test subject'
    fill_in 'post_content', with: 'test content'
    click_button 'Post'


    aggregate_failures do
      expect(page).to have_selector('.flash.error', text: "Post could not be created because of the following problems:\nBoard must exist")
      expect(page).to have_selector('#post-editor')
      within('#post-editor') do
        expect(page).to have_selector('.view-button.selected', text: 'HTML')
        expect(page).to have_field('Subject', with: 'test subject')
        expect(page).to have_field('post_content', with: 'test content')
      end
    end
  end

  scenario "User sees different editor settings" do
    user = login

    visit new_post_path

    expect(find('#current-icon-holder img')[:src]).to eq('/assets/icons/no-icon.png')

    icon = create(:icon, user: user)
    user.update!(avatar: icon)

    visit new_post_path

    expect(find('#current-icon-holder img')[:src]).to eq(icon.url)

    icon2 = create(:icon, user: user)
    character = create(:character, user: user, default_icon: icon2)
    user.update!(active_character: character)

    visit new_post_path

    expect(find('#current-icon-holder img')[:src]).to eq(icon2.url)
  end

  scenario "Continuity settings show up", :js do
    login
    board = create(:board)
    create(:board)
    create(:board_section, board: board, name: "Th<em> pirates")
    create(:board_section, board: board, name: "Th/ose/ aliens")

    visit new_post_path
    select(board.name, from: "Continuity:")

    expect(page).to have_select('Continuity section:')

    select("Th<em> pirates", from: "Continuity section:")
  end
end
