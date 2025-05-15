RSpec.describe "Create new block" do
  let(:user) { create(:user, username: 'John Doe') }
  let(:blocked) { create(:user, username: 'Person You Want To Block') }

  before(:each) { login(user) }

  scenario "Creating an invalid block" do
    visit new_block_path(block: { blocked_user_id: blocked.id })

    aggregate_failures do
      expect(page).to have_selector('.breadcrumbs', text: 'Blocks » New')

      within('.form-table') do
        expect(page).to have_selector('.editor-title', text: 'Block User')
        expect(page).to have_select('User', selected: 'Person You Want To Block')
      end
    end

    within('.form-table') do
      uncheck 'Interactions'
      click_button 'Save'
    end

    aggregate_failures do
      error_msg = "User could not be blocked because of the following problems:\nBlock must choose at least one action to prevent"
      expect(page).to have_selector('.flash.error', text: error_msg)
      expect(page).to have_selector('.form-table')
    end
  end

  scenario "User blocks another from their userpage" do
    visit user_path(blocked)
    click_link 'Block'

    aggregate_failures do
      expect(page).to have_selector('.breadcrumbs', text: 'Blocks » New')

      within('.form-table') do
        expect(page).to have_selector('.editor-title', text: 'Block User')
        expect(page).to have_select('User', selected: 'Person You Want To Block')
      end
    end

    within('.form-table') do
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', text: 'User blocked.')
      expect(page).to have_selector('.table-title', text: 'Blocked Users')

      within('tbody') do
        expect(page).to have_selector('tr', count: 1)
        expect(page).to have_selector('tr', text: 'Person You Want To Block')
      end
    end
  end

  scenario "User blocks another from blocks#index" do
    skip "Due to ajax loading this doesn't actually work atm"

    visit blocks_path
    click_link '+ Block User'

    aggregate_failures do
      expect(page).to have_selector('.breadcrumbs', text: 'Blocks » New')
      expect(page).to have_selector('.form-table .editor-title', text: 'Block User')
    end

    within('.form-table') do
      select 'Person You Want To Block', from: 'User'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', text: 'User blocked.')
      expect(page).to have_selector('.table-title', text: 'Blocked Users')

      within('tbody') do
        expect(page).to have_selector('tr', count: 1)
        expect(page).to have_selector('tr', text: 'Person You Want To Block')
      end
    end
  end
end
