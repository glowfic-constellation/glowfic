RSpec.describe "Replacing characters" do
  scenario "Selecting a character with aliases", :js do
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
      select "Alice"
      select "Fred the <strong>!"
    end

    within("#alias_dropdown") { select "The <strong>!" }
  end

  # TODO: test actual replacement!
end
