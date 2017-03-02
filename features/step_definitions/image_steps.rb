Then(/^I should (not )?see the (.+) icon$/) do |neg, image|
  if neg
    expect(page).not_to have_xpath("//img[contains(@src, '#{image}')]")
  else
    expect(page).to have_xpath("//img[contains(@src, '#{image}')]")
  end
end
