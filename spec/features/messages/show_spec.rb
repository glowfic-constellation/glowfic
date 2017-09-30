require "spec_helper"

RSpec.feature "Message threads", :type => :feature do
  scenario "User views a message thread" do
    user = login

    first = create(:message, sender: user)
    second = create(:message, thread_id: first.id, sender: first.recipient, recipient: user)
    third = create(:message, thread_id: first.id, sender: user, recipient: first.recipient)

    visit messages_path(view: 'inbox')
    expect(page).to have_selector('td.padding-5', count: 1)
    within("table") do
      click_link first.unempty_subject
    end
    expect(page).to have_selector('.message-collapse', count: 3)

    long = create(:message, thread_id: first.id, sender: user, recipient: first.recipient, message: "abcde" * 22)
    visit messages_path(view: 'outbox')
    within("table") do
      click_link first.unempty_subject
    end
    expect(page).to have_selector('.message-collapse', count: 4)
    short = ("abcde" * 15)[0...73] + "…"
    expect(page).to have_selector('.message-collapse', text: short)
    expect(page).to have_no_selector('.message-collapse', text: "abcde" * 20)
  end
end
