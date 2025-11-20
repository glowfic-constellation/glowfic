RSpec.describe "Message threads" do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:outgoing1) { create(:message, sender: user, recipient: other_user) }
  let(:outgoing2) { create(:message, sender: user) }
  let(:incoming1) { create(:message, sender: other_user, recipient: user) }
  let(:incoming2) { create(:message, recipient: user) }
  let(:thread1) { create(:message, thread_id: outgoing1.id, sender: other_user, recipient: user) }
  let(:thread2) { create(:message, thread_id: outgoing1.id, sender: user, recipient: other_user) }

  scenario "User views a message thread" do
    login(user)

    [outgoing1, thread1, thread2]

    visit messages_path(view: 'inbox')
    expect(page).to have_selector('.message-row', count: 1)

    click_link outgoing1.unempty_subject
    expect(page).to have_selector('.message-collapse', count: 3)

    create(:message, thread_id: outgoing1.id, sender: user, recipient: other_user, message: "abcde" * 22)

    visit messages_path(view: 'outbox')
    click_link outgoing1.unempty_subject

    aggregate_failures do
      expect(page).to have_selector('.message-collapse', count: 4)
      short = ("abcde" * 15)[0...73] + "…"
      expect(page).to have_selector('.message-collapse', text: short)
      expect(page).to have_no_selector('.message-collapse', text: "abcde" * 20)
    end
  end

  scenario "ordering of inbox messages within threading" do
    login(user)

    [incoming1, incoming2]

    visit messages_path(view: 'inbox')

    aggregate_failures do
      expect(page).to have_selector('.message-row', count: 2)
      table_rows = all('.message-row')
      expect(table_rows[0]).to have_text(incoming2.unempty_subject)
      expect(table_rows[1]).to have_text(incoming1.unempty_subject)
    end

    create(:message, thread_id: incoming1.id, sender: other_user, recipient: user)

    visit messages_path(view: 'inbox')

    aggregate_failures do
      expect(page).to have_selector('.message-row', count: 2)
      table_rows = all('.message-row')
      expect(table_rows[0]).to have_text(incoming1.unempty_subject)
      expect(table_rows[1]).to have_text(incoming2.unempty_subject)
    end
  end

  scenario "ordering of outbox messages within threading" do
    login(user)

    [outgoing1, outgoing2]

    visit messages_path(view: 'outbox')

    aggregate_failures do
      expect(page).to have_selector('.message-row', count: 2)
      table_rows = all('.message-row')
      expect(table_rows[0]).to have_text(outgoing2.unempty_subject)
      expect(table_rows[1]).to have_text(outgoing1.unempty_subject)
    end

    thread2
    visit messages_path(view: 'outbox')

    aggregate_failures do
      expect(page).to have_selector('.message-row', count: 2)
      table_rows = all('.message-row')
      expect(table_rows[0]).to have_text(outgoing1.unempty_subject)
      expect(table_rows[1]).to have_text(outgoing2.unempty_subject)
    end
  end

  scenario "check-all checkbox works", :js do
    user = login
    visit messages_path(view: 'inbox')

    aggregate_failures do
      expect(page).to have_selector('.table-title', text: 'Inbox')
      expect(page).to have_no_selector('.check-all')
      expect(page).to have_no_selector('.check-all-item[name="marked_ids[]"]')
    end

    create_list(:message, 2, recipient: user)
    visit messages_path(view: 'inbox')

    check_all_boxes = find('.check-all[data-check-box-name="marked_ids[]"]')
    message_checkboxes = all('.check-all-item[name="marked_ids[]"]')

    aggregate_failures do
      expect(check_all_boxes).to be_present
      expect(message_checkboxes.length).to be(2)
    end

    check_all_boxes.click
    expect(message_checkboxes).to all(be_checked)

    check_all_boxes.click
    expect(message_checkboxes).not_to include(be_checked)

    message_checkboxes[0].click
    expect(check_all_boxes).not_to be_checked

    message_checkboxes[1].click
    expect(check_all_boxes).to be_checked

    message_checkboxes[0].click
    expect(check_all_boxes).not_to be_checked

    check_all_boxes.click
    expect(message_checkboxes[0]).to be_checked
  end
end
