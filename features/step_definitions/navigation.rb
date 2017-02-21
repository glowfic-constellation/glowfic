Given(/^I am logged in$/) do
  user = create(:user, password: 'secret')
  visit root_path
  fill_in "username", with: user.username
  fill_in "password", with: 'secret'
  click_button "Log in"
end

When(/^I start a new post$/) do
  visit new_post_path
end

Then(/^I should see "(.*)"$/) do |content|
  expect(page).to have_content(content)
end
