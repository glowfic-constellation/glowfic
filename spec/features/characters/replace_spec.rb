RSpec.feature "Replacing characters", type: :feature do
  scenario "Selecting a character with aliases", js: true do
    user = login
    fred = create(:character, user: user, name: "Fred the <strong>!")
    create(:alias, character: fred, name: "Fred")
    create(:alias, character: fred, name: "The <strong>!")
    john = create(:character, user: user, name: "John")
    create(:character, user: user, name: "Alice")

    visit character_path(john)
    click_link "Replace Character"

    expect(page).to have_text("Replace All Uses of Character")

    within("#icon_dropdown") do
      page.select "Alice"
      page.select "Fred the <strong>!"
    end
    within("#alias_dropdown") { page.select "The <strong>!" }
  end

  # TODO: test actual replacement!
end
