RSpec.describe "Creating a new character" do
  let(:user) { create(:user) }
  let(:icons) do
    create_list(:icon, 2, user: user).append(create(:icon, user: user, keyword: 'Example icon'))
  end

  scenario "Create an invalid character", :js do
    # view new character form without being logged in
    visit new_character_path
    expect(page).to have_selector('.flash.error', exact_text: 'You must be logged in to view that page.')

    # view new character form with no icons
    login(user)
    visit new_character_path
    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'New Character')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_no_selector('img.icon')
    end

    # view new character form with icons
    icons
    visit new_character_path

    expect(page).to have_selector('img.icon', count: 3)

    # create character with no name
    find("img[alt='Example icon']").click

    aggregate_failures do
      expect(page).to have_selector('.selected-icon')
      expect(find('.selected-icon')[:alt]).to eq('Example icon')
    end

    within('.form-table') do
      fill_in 'Template Nickname', with: 'Example nickname'
      fill_in 'Screen Name', with: 'example_screenname'
      fill_in 'Facecast', with: 'Example facecast'
      fill_in 'Description', with: 'Example description'
      click_button 'Save'
    end

    aggregate_failures do
      error_msg = "Character could not be created because of the following problems:\nName can't be blank"
      expect(page).to have_selector('.flash.error', exact_text: error_msg)

      # check that it preserved inputs
      expect(page).to have_selector('.selected-icon')
      expect(find('.selected-icon')[:alt]).to eq('Example icon')

      within('.form-table') do
        expect(page).to have_field('Template Nickname', with: 'Example nickname')
        expect(page).to have_field('Screen Name', with: 'example_screenname')
        expect(page).to have_field('Facecast', with: 'Example facecast')
        expect(page).to have_field('Description', with: 'Example description')
      end
    end
  end

  scenario "Create a simple character" do
    login
    visit new_character_path

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'New Character')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      fill_in 'Character Name', with: 'Example character'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Character created.')
      expect(page).to have_no_selector('.flash.error')
    end
  end

  scenario "Create an NPC character", :js do
    login
    visit new_character_path

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'New Character')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      fill_in 'Character Name', with: 'Example character'
      check 'NPC?'

      expect(page).to have_field('Template Cluster Name', disabled: true)

      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Character created.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.info-box-header', exact_text: "Example character\n(NPC)")
    end
  end

  scenario "Creating character with icon, description and extant template", :js do
    login(user)
    icon = icons[2]
    template = create(:template, user: user, name: 'Example template')
    create(:template, user: user)
    visit new_character_path(template_id: template.id)

    aggregate_failures do
      expect(page).to have_selector('#select2-character_template_id-container', text: 'Example template')
      expect(page).to have_no_selector('.flash.error')
    end

    find("img[alt='Example icon']").click
    within('.form-table') do
      fill_in 'Character Name', with: 'Example character'
      fill_in 'Template Nickname', with: 'Example nickname'
      fill_in 'Screen Name', with: 'example_screenname'
      fill_in 'Facecast', with: 'Example facecast'
      fill_in 'Description', with: 'Example description'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Character created.')
      expect(page).to have_no_selector('.flash.error')

      within('.character-info-box') do
        expect(page).to have_selector('.character-name', text: 'Example character')
        expect(page).to have_selector('.character-screenname', text: 'example_screenname')
        expect(page).to have_selector('.character-icon')

        within('.character-icon') do
          expect(find('a')[:href]).to include("/icons/#{icon.id}")
          expect(find('img')[:alt]).to eq('Example icon')
        end
      end

      within('.character-right-content-box') do
        expect(page).to have_selector('.character-template', text: 'Example template')
        expect(page).to have_selector('.character-pb', text: 'Example facecast')
        expect(page).to have_selector('.character-description', text: 'Example description')
      end
    end
  end

  scenario "Creating character with new template" do
    login
    visit new_character_path

    aggregate_failures do
      expect(page).to have_selector('.editor-title', text: 'New Character')
      expect(page).to have_no_selector('.flash.error')
    end

    within('.form-table') do
      fill_in 'Character Name', with: 'Example character'
      check 'new_template'
      fill_in 'Template Name', with: 'Example template'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', text: 'Character created.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.character-template', text: 'Example template')
    end
  end
end
