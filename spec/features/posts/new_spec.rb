require "spec_helper"

RSpec.feature "Creating posts", :type => :feature do
  scenario "User creates a post" do
    visit new_post_path
    within(".error") { expect(page).to have_text("You must be logged in") }

    user = login
    create(:board)

    visit new_post_path
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector(".content-header", text: "Create a new post")

    click_button "Post"
    within(".error") { expect(page).to have_text("Subject can't be blank") }
    expect(page).to have_selector(".content-header", text: "Create a new post")

    fill_in "post_subject", with: "test subject"
    click_button "Post"
    expect(page).to have_no_selector(".error")
    within(".success") { expect(page).to have_text("successfully posted.") }
  end

  scenario "User sees different editor settings" do
    user = login
    create(:board)

    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath("//img[contains(@src, 'no-icon')]")
    end

    icon = create(:icon, user: user)
    user.update_attributes(avatar: icon)
    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath("//img[contains(@src, '#{icon.url}')]")
    end

    icon2 = create(:icon, user: user)
    character = create(:character, user: user, default_icon: icon2)
    user.update_attributes(active_character: character)
    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath("//img[contains(@src, '#{icon2.url}')]")
    end
  end
end
