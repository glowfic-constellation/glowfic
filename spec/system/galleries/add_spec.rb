RSpec.describe "Adding icons to a gallery" do
  let(:user) { create(:user) }
  let(:gallery) { create(:gallery, user: user) }

  scenario "Adding new hotlinked icons", :js do
    login(user)
    visit gallery_path(gallery)
    click_link '+ Add Icons'

    expect(page).to have_selector('.content-header', text: 'Add New Icons to Gallery')

    within(first('.icon-row')) do
      fill_in 'URL', with: 'https://example.com/icon.png'
      fill_in 'Keyword', with: 'test icon 1'
      fill_in 'Credit', with: 'Test credit'
      click_link 'Add Row'
    end

    within(all('.icon-row').last) do
      fill_in 'URL', with: 'https://example.com/icon2.png'
      fill_in 'Keyword', with: 'test icon 2'
      click_link 'Add Row'
    end

    expect(page).to have_selector('.icon-row', count: 3)

    within(all('.icon-row').last) do
      click_link 'Delete Row'
    end

    expect(page).to have_selector('.icon-row', count: 2)

    click_button 'Add New Icons'

    expect(page).to have_selector('.flash.success', exact_text: 'Icons saved.')

    click_link 'Icons', href: /view=icons/

    aggregate_failures do
      within('.icons-box') do
        expect(page).to have_selector('.gallery-icon', count: 2)
        expect(page).to have_selector('img', count: 2)

        within(first('.gallery-icon')) do
          expect(page).to have_selector('.icon-keyword', exact_text: 'test icon 1')
          expect(find('img')[:src]).to eq('https://example.com/icon.png')
        end

        within(all('.gallery-icon')[1]) do
          expect(page).to have_selector('.icon-keyword', exact_text: 'test icon 2')
          expect(find('img')[:src]).to eq('https://example.com/icon2.png')
        end
      end
    end
  end

  skip "Adding new uploaded icons", :js do
    skip "not yet implemented: requires more complex capybara interaction with forms"
  end

  scenario "Adding existing icons", :js do
    login(user)
    create(:icon, user: user, keyword: "test icon 1")

    visit gallery_path(gallery)
    click_link '+ Add Icons'
    click_link 'Add Existing Icons »'

    aggregate_failures do
      expect(page).to have_selector('.content-header', text: 'Add Existing Icons to Gallery')
      expect(page).to have_selector('.icon-keyword', exact_text: 'test icon 1')
    end

    find('.gallery-icon', text: 'test icon 1').find('img').click
    first(:button, 'Add Icons to Gallery').click

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Icons added to gallery.')
      expect(page).to have_selector('.icon-keyword', exact_text: 'test icon 1')
    end
  end
end
