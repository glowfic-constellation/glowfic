RSpec.describe "Create new block" do
  let(:user) { create(:user, username: 'John Doe', password: known_test_password) }
  let(:blocked) { create(:user, username: 'Person You Want To Block') }

  scenario "Creating an invalid block" do
    login(user, known_test_password)

    visit new_block_path(block: { blocked_user_id: blocked.id })

    expect(page).to have_selector('.breadcrumbs', text: 'Blocks » New')

    within('.form-table') do
      expect(page).to have_selector('.editor-title', text: 'Block User')
      expect(page).to have_select('User', selected: 'Person You Want To Block')

      uncheck 'Interactions'
      click_button 'Save'
    end

    error_msg = "User could not be blocked because of the following problems:\nBlock must choose at least one action to prevent"
    expect(page).to have_selector('.flash.error', text: error_msg)
    expect(page).to have_selector('.form-table')
  end

  scenario "User blocks another from their userpage" do
    login(user, known_test_password)

    visit user_path(blocked)
    click_link 'Block'

    expect(page).to have_selector('.breadcrumbs', text: 'Blocks » New')

    within('.form-table') do
      expect(page).to have_selector('.editor-title', text: 'Block User')
      expect(page).to have_select('User', selected: 'Person You Want To Block')

      click_button 'Save'
    end

    expect(page).to have_selector('.flash.success', text: 'User blocked.')
    expect(page).to have_selector('.table-title', text: 'Blocked Users')

    within('tbody') do
      expect(page).to have_selector('tr', count: 1)
      expect(page).to have_selector('tr', text: 'Person You Want To Block')
    end
  end

  scenario "User blocks another from blocks#index" do
    skip "Due to ajax loading this doesn't actually work atm"
    login(user, known_test_password)

    visit blocks_path
    click_link '+ Block User'

    expect(page).to have_selector('.breadcrumbs', text: 'Blocks » New')

    within('.form-table') do
      expect(page).to have_selector('.editor-title', text: 'Block User')
      select 'Person You Want To Block', from: 'User'

      click_button 'Save'
    end

    expect(page).to have_selector('.flash.success', text: 'User blocked.')
    expect(page).to have_selector('.table-title', text: 'Blocked Users')

    within('tbody') do
      expect(page).to have_selector('tr', count: 1)
      expect(page).to have_selector('tr', text: 'Person You Want To Block')
    end
  end
end
