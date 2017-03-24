Then(/^I should see (\d+) posts?$/) do |num|
  expect(page).to have_selector('.post-subject', count: num)
end
