RSpec.describe "Edit a single continuity" do
  scenario "Continuity can be edited" do
    board = create(:board, name: 'Test board')

    login(board.creator)

    visit continuity_path(board)
    expect(page).to have_selector('.table-title', text: 'Test board')

    click_link 'Edit'

    fill_in 'Continuity Name', with: 'Edited board'
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Continuity updated.')
      expect(page).to have_no_selector('.flash.error')
      expect(page).to have_selector('.table-title', text: 'Edited board')
    end
  end
end
