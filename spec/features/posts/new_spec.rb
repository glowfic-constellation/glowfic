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
    expect(page).to have_selector('.error', text: "Subject can't be blank")
    expect(page).to have_selector(".content-header", text: "Create a new post")

    fill_in "post_subject", with: "test subject"
    click_button "Post"
    expect(page).to have_no_selector(".error")
    expect(page).to have_selector('.success', text: 'successfully posted.')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('#post-title', exact_text: 'test subject')

    within('.post-container') do
      expect(page).to have_selector('.post-author', exact_text: user.username)
      expect(page).to have_selector('.post-content', exact_text: '')
    end
  end

  scenario "User sees different editor settings" do
    user = login
    create(:board)

    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath(".//img[contains(@src, 'no-icon')]")
    end

    icon = create(:icon, user: user)
    user.update!(avatar: icon)
    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath(".//img[contains(@src, '#{icon.url}')]")
    end

    icon2 = create(:icon, user: user)
    character = create(:character, user: user, default_icon: icon2)
    user.update!(active_character: character)
    visit new_post_path
    within("#current-icon-holder") do
      expect(page).to have_xpath(".//img[contains(@src, '#{icon2.url}')]")
    end
  end
end
