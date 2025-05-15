RSpec.describe "Editing a character" do
  scenario "Updating a basic character", :js do
    user = create(:user, password: known_test_password)
    character = create(:character, user: user)
    visit edit_character_path(character)
    expect(page).to have_selector('.flash.error', text: "You must be logged in")

    login(user, known_test_password)
    visit edit_character_path(character)

    aggregate_failures do
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_no_text("You must be logged in")
      expect(page).to have_selector(".editor-title", text: character.name)
    end

    within('.character-form') do
      fill_in 'Template Nickname', with: 'Example nickname'
      fill_in 'Screen Name', with: 'example_screenname'
      fill_in 'Facecast', with: 'Example facecast'
      fill_in 'Description', with: 'Example description'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.flash.success')
      within('.flash.success') do
        expect(page).to have_text('Character updated.')
      end
      expect(page).to have_text('Example nickname')
      expect(page).to have_text('example_screenname')
      expect(page).to have_text('Example facecast')
      expect(page).to have_text('Example description')
    end
  end

  scenario "Updating an NPC character", :js do
    user = login
    character = create(:character, name: "MyChar", user: user, npc: true, nickname: "Thread")

    # update facecast of NPC
    visit edit_character_path(character)
    within('.character-form') do
      aggregate_failures do
        expect(page).to have_field('Template Cluster Name', disabled: true)
        expect(page).to have_field('Facecast', disabled: false)
      end

      fill_in "Facecast", with: "Example facecast"
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.flash.success')
      within('.flash.success') do
        expect(page).to have_text('Character updated.')
      end
      expect(page).to have_text(/MyChar\s+\(NPC\)/)
      expect(page).to have_text('Example facecast')
      expect(page).to have_text(/Original post.*Thread/)
    end

    # turn NPC into non-NPC
    visit edit_character_path(character)
    within('.character-form') do
      aggregate_failures do
        expect(page).to have_field('Template Cluster Name', disabled: true)
        expect(page).to have_field('Facecast', disabled: false)
      end

      uncheck 'NPC?'

      aggregate_failures do
        expect(page).to have_field('Template Cluster Name', disabled: false)
        expect(page).to have_field('Facecast', disabled: false)
      end

      fill_in "Screenname", with: "example_screenname"
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.flash.success')
      within('.flash.success') do
        expect(page).to have_text('Character updated.')
      end
      expect(page).to have_no_text('(NPC)')
      expect(page).to have_text('example_screenname')
      expect(page).to have_text(/Nickname.*Thread/)
    end
  end
end
