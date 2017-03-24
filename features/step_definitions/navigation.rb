def current_user
  @user
end

Given(/^I am logged in$/) do
  @user = create(:user, password: 'secret')
  visit root_path
  fill_in "username", with: @user.username
  fill_in "password", with: 'secret'
  click_button "Log in"
end

Given(/^I have (\d) galleryless icons?$/) do |num|
  num.to_i.times do create(:icon, user: current_user) end
end

Given(/^I have (\d) unread posts?$/) do |num|
  num.to_i.times do
    unread = create(:post)
    create(:reply, user: unread.user, post: unread)
  end
end

Given(/^I have (\d) partially-read posts?$/) do |num|
  num.to_i.times do
    unread = Timecop.freeze(Time.now - 1.day) do
      unread = create(:post)
      unread.mark_read(current_user)
      unread
    end
    create(:reply, user: unread.user, post: unread)
  end
end

Given(/^I have (\d) read posts?$/) do |num|
  num.to_i.times do
    read = create(:post)
    read.mark_read(current_user)
  end
end

Given(/^my account uses the (.+) layout$/) do |layout|
  layout_name = layout.gsub(" ", "")
  user = current_user
  user.layout = layout_name
  user.save!
end

When(/^I start a new post$/) do
  visit new_post_path
end

When(/^I go to create a new character$/) do
  visit new_character_path
end

When(/^I view my unread posts$/) do
  visit unread_posts_path
end

Then(/^I should see "(.*)"$/) do |content|
  expect(page).to have_content(content)
end

Then(/^I should not see "(.*)"$/) do |content|
  expect(page).not_to have_content(content)
end
