RSpec.describe "Adding icons to a gallery" do
  scenario "Adding new hotlinked icons", :js do
    user = login
    gallery = create(:gallery, user: user)
    visit gallery_path(gallery)
    click_link "+ Add Icons"

    expect(page).to have_text("Add New Icons to Gallery")
    within(all('.icon-row').last) do
      fill_in "URL", with: "https://example.com/icon.png"
      fill_in "Keyword", with: "test icon 1"
      fill_in "Credit", with: "Test credit"
      click_link "Add Row"
    end

    within(all('.icon-row').last) do
      fill_in "URL", with: "https://example.com/icon2.png"
      fill_in "Keyword", with: "test icon 2"
      click_link "Add Row"
    end

    expect(page).to have_selector('.icon-row', count: 3)
    within(all('.icon-row').last) do
      click_link "Delete Row"
    end
    expect(page).to have_selector('.icon-row', count: 2)

    click_button "Add New Icons"

    expect(page).to have_text("Icons saved.")
    click_link "Icons", href: /view=icons/

    within(".icons-box") do
      expect(page).to have_text("test icon 1")
      expect(page).to have_text("test icon 2")
      expect(page).to have_selector("img", count: 2)
      expect(page).to have_selector("img") { |elem| elem[:src] == "https://example.com/icon.png" }
      expect(page).to have_selector("img") { |elem| elem[:src] == "https://example.com/icon2.png" }
    end
  end

  skip "Adding new uploaded icons", :js do
    skip "not yet implemented: requires more complex capybara interaction with forms"
  end

  scenario "Adding existing icons", :js do
    user = login
    gallery = create(:gallery, user: user)
    create(:icon, user: user, keyword: "test icon 1")

    visit gallery_path(gallery)
    click_link "+ Add Icons"
    click_link "Add Existing Icons »"

    expect(page).to have_text("Add Existing Icons to Gallery")
    expect(page).to have_text("test icon 1")
    icon = page.find(".gallery-icon", text: "test icon 1")
    icon.find("img").click
    first(:button, "Add Icons to Gallery").click

    expect(page).to have_text("Icons added to gallery.")
    expect(page).to have_text("test icon 1")
  end
end
