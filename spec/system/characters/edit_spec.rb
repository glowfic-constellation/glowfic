RSpec.describe "Editing a character" do
  let(:user) { create(:user) }
  let(:character) { create(:character, user: user) }

  scenario "Updating a basic character", :js do
    visit edit_character_path(character)

    expect(page).to have_selector('.flash.error', exact_text: 'You must be logged in to view that page.')

    login(user)
    visit edit_character_path(character)

    expect(page).to have_selector('.editor-title', text: character.name)
    expect(page).to have_no_selector('.flash.error')

    within('.character-form') do
      fill_in 'Template Nickname', with: 'Example nickname'
      fill_in 'Screen Name', with: 'example_screenname'
      fill_in 'Facecast', with: 'Example facecast'
      fill_in 'Description', with: 'Example description'
      click_button 'Save'
    end

    expect(page).to have_selector('.flash.success', exact_text: 'Character updated.')
    expect(page).to have_no_selector('.flash.error')

    expect(page).to have_text('Example nickname')
    expect(page).to have_text('example_screenname')
    expect(page).to have_text('Example facecast')
    expect(page).to have_text('Example description')
  end

  scenario "Updating an NPC character", :js do
    character.update!(name: 'MyChar', npc: true, nickname: 'Thread')
    login(user)

    # update facecast of NPC
    visit edit_character_path(character)
    within('.character-form') do
      expect(page).to have_field('Template Cluster Name', disabled: true)
      expect(page).to have_field('Facecast', disabled: false)

      fill_in 'Facecast', with: 'Example facecast'
      click_button 'Save'
    end

    expect(page).to have_selector('.flash.success', exact_text: 'Character updated.')
    expect(page).to have_no_selector('.flash.error')

    expect(page).to have_selector('.info-box-header', exact_text: "MyChar\n(NPC)")
    expect(page).to have_selector('.character-pb', exact_text: 'Example facecast')
    expect(page).to have_text(/Original post.*Thread/)

    # turn NPC into non-NPC
    visit edit_character_path(character)
    within('.character-form') do
      expect(page).to have_field('Template Cluster Name', disabled: true)
      expect(page).to have_field('Facecast', disabled: false)

      uncheck 'NPC?'
      expect(page).to have_field('Template Cluster Name', disabled: false)
      expect(page).to have_field('Facecast', disabled: false)

      fill_in 'Screenname', with: 'example_screenname'
      click_button 'Save'
    end

    expect(page).to have_selector('.flash.success', exact_text: 'Character updated.')
    expect(page).to have_no_selector('.flash.error')

    expect(page).to have_no_text('(NPC)')
    expect(page).to have_selector('.character-screenname', exact_text: 'example_screenname')
    expect(page).to have_text(/Nickname.*Thread/)
  end
end
