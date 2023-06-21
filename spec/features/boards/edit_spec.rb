RSpec.feature "Edit a single continuity", type: :feature do
  scenario "Continuity can be edited" do
    board = create(:board, name: "Test continuity")
    login(board.creator, 'password')
    visit continuity_path(board)
    expect(page).to have_text("Test continuity")
    click_link "Edit"
    fill_in 'Continuity Name', with: 'Edited continuity'
    click_button 'Save'
    expect(page).to have_no_selector('.error')
    expect(page).to have_selector('.success', text: 'Continuity saved!')
    expect(page).to have_text("Edited continuity")
  end
end
