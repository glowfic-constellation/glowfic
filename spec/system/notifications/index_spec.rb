RSpec.describe "User notifications" do
  scenario "check-all checkbox works", :js do
    user = login
    visit notifications_path

    aggregate_failures do
      expect(page).to have_selector('.content-header', text: 'Notifications')
      expect(page).to have_no_selector('.check-all')
      expect(page).to have_no_selector('.check-all-item[name="marked_ids[]"]')
    end

    create_list(:notification, 2, user: user, notification_type: :new_favorite_post)
    visit notifications_path

    check_all_boxes = find('.check-all[data-check-box-name="marked_ids[]"]')
    notification_checkboxes = all('.check-all-item[name="marked_ids[]"]')

    aggregate_failures do
      expect(check_all_boxes).to be_present
      expect(notification_checkboxes.length).to be(2)
    end

    check_all_boxes.click
    expect(notification_checkboxes).to all(be_checked)

    check_all_boxes.click
    expect(notification_checkboxes).not_to include(be_checked)

    notification_checkboxes[0].click
    expect(check_all_boxes).not_to be_checked

    notification_checkboxes[1].click
    expect(check_all_boxes).to be_checked

    notification_checkboxes[0].click
    expect(check_all_boxes).not_to be_checked

    check_all_boxes.click
    expect(notification_checkboxes[0]).to be_checked
  end
end
