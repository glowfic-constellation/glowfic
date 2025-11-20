RSpec.describe "Adding a character alias" do
  scenario "Adding successfully" do
    user = login
    character = create(:character, user: user)

    visit characters_path

    click_link character.name
    click_link "Edit Character"

    aggregate_failures do
      expect(page).to have_field('Character Name', with: character.name)
      expect(page).to have_no_text("AnAlias")
    end

    click_link "New Alias"
    fill_in "Alias", with: "AnAlias"
    click_button 'Save'

    aggregate_failures do
      expect(page).to have_selector('.flash.success', exact_text: 'Alias created.')
      expect(page).to have_text("AnAlias")
    end
  end
end
