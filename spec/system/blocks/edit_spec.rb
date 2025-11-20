RSpec.describe "Edit a block" do
  let(:user) { create(:user, username: 'John Doe') }
  let(:blocked) { create(:user, username: 'Person You Want To Block') }
  let(:block) { create(:block, blocking_user: user, blocked_user: blocked, block_interactions: true, hide_them: :posts) }

  before(:each) { login(user) }

  scenario 'Edit an invalid block' do
    visit edit_block_path(block)

    aggregate_failures do
      expect(page).to have_selector('.breadcrumbs', text: 'Blocks » Block on Person You Want To Block » Edit')

      within('.form-table') do
        expect(page).to have_selector('.editor-title', text: 'Edit Block')
        expect(page).to have_text('Person You Want To Block')
      end
    end

    within('.form-table') do
      uncheck 'Interactions'
      select 'Nothing', from: 'Hide them'
      click_button 'Save'
    end

    aggregate_failures do
      error_msg = "Block could not be updated because of the following problems:\nBlock must choose at least one action to prevent"
      expect(page).to have_selector('.flash.error', text: error_msg)
      expect(page).to have_selector('.form-table')
    end
  end

  scenario 'Edit a block' do
    visit edit_block_path(block)

    aggregate_failures do
      expect(page).to have_selector('.breadcrumbs', text: 'Blocks » Block on Person You Want To Block » Edit')

      within('.form-table') do
        expect(page).to have_selector('.editor-title', text: 'Edit Block')
        expect(page).to have_text('Person You Want To Block')
      end
    end

    within('.form-table') do
      uncheck 'Interactions'
      select 'Everything', from: 'Hide yourself'
      click_button 'Save'
    end

    aggregate_failures do
      expect(page).to have_selector('.flash.success', text: 'Block updated.')
      expect(page).to have_selector('.table-title', text: 'Blocked Users')

      within('tbody') do
        expect(page).to have_selector('tr', count: 1)
        expect(page).to have_selector('tr', text: 'Person You Want To Block')

        within('tr', text: 'Person You Want To Block') do
          expect(page).to have_selector('td', text: 'No', exact_text: true)
          expect(page).to have_selector('td', text: 'Posts', exact_text: true)
          expect(page).to have_selector('td', text: 'All', exact_text: true)
        end
      end
    end
  end
end
