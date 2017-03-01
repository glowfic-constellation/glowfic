Given(/^I am logged in$/) do
  user = create(:user, password: 'secret')
  visit root_path
  fill_in "username", with: user.username
  fill_in "password", with: 'secret'
  click_button "Log in"
end

Given(/^I have a message thread$/) do
  first = create(:message, sender: User.last)
  second = create(:message, thread_id: first.id, sender: first.recipient, recipient: first.sender, parent: first)
  last = create(:message, thread_id: first.id, sender: first.sender, recipient: first.recipient, parent: second)
end

Given(/^I have a long message$/) do
  create(:message, sender: User.last, message: "abcde" * 22)
end

Given(/^I have (\d) galleryless icons?$/) do |num|
  num.to_i.times do create(:icon, user: User.last) end
end

Given(/^I have (\d) unread posts?$/) do |num|
  num.to_i.times do
    unread = create(:post)
    unread.mark_read(User.first, Time.now - 1.day)
    create(:reply, user: unread.user, post: unread)
  end
end

When(/^I start a new post$/) do
  visit new_post_path
end

When(/^I go to create a new character$/) do
  visit new_character_path
end

When(/^I go to my (in|out)box$/) do |box|
  visit messages_path(view: box + "box")
end

When(/^I view my unread posts$/) do
  visit unread_posts_path
end

When(/^I open the message$/) do
  within("#content") do
    click_link Message.last.unempty_subject
  end
end

Then(/^I should see "(.*)"$/) do |content|
  expect(page).to have_content(content)
end

Then(/^I should not see "(.*)"$/) do |content|
  expect(page).not_to have_content(content)
end

Then(/^I should see (\d) messages$/) do |num|
  expect(page).to have_selector('.message-collapse', count: num)
end

Then(/^I should see the shortened message$/) do
  within(".message-collapse") do
    expect(page).to have_content("abcde" * 15 + "...")
    expect(page).not_to have_content("abcde" * 20)
  end
end
