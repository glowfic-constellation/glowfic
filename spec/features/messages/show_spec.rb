require "spec_helper"

RSpec.feature "Message threads", :type => :feature do
  scenario "User views a message thread" do
    user = login

    first = create(:message, sender: user)
    second = create(:message, thread_id: first.id, sender: first.recipient, recipient: user)
    third = create(:message, thread_id: first.id, sender: user, recipient: first.recipient)

    visit messages_path(view: 'inbox')
    expect(page).to have_selector('tr.message-row', count: 1)
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

  scenario "ordering of inbox messages within threading" do
    user = login
    first = create(:message, recipient: user, subject: 'first')
    second = create(:message, recipient: user, subject: 'second')

    visit messages_path(view: 'inbox')
    expect(page).to have_selector('tr.message-row', count: 2)
    table_rows = page.all(:css, 'tr.message-row')
    expect(table_rows[0]).to have_text('second')
    expect(table_rows[1]).to have_text('first')

    third = create(:message, thread_id: first.id, recipient: user, sender: first.sender)
    visit messages_path(view: 'inbox')
    expect(page).to have_selector('tr.message-row', count: 2)
    table_rows = page.all(:css, 'tr.message-row')
    expect(table_rows[0]).to have_text('first')
    expect(table_rows[1]).to have_text('second')
  end

  scenario "ordering of outbox messages within threading" do
    user = login
    first = create(:message, sender: user, subject: 'first')
    second = create(:message, sender: user, subject: 'second')

    visit messages_path(view: 'outbox')
    expect(page).to have_selector('tr.message-row', count: 2)
    table_rows = page.all(:css, 'tr.message-row')
    expect(table_rows[0]).to have_text('second')
    expect(table_rows[1]).to have_text('first')

    third = create(:message, thread_id: first.id, recipient: first.recipient, sender: user)
    visit messages_path(view: 'outbox')
    expect(page).to have_selector('tr.message-row', count: 2)
    table_rows = page.all(:css, 'tr.message-row')
    expect(table_rows[0]).to have_text('first')
    expect(table_rows[1]).to have_text('second')
  end
end
