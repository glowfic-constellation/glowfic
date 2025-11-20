RSpec.describe "Unread posts" do
  scenario "User views their unread page" do
    visit unread_posts_path
    expect(page).to have_selector('.flash.error', exact_text: 'You must be logged in to view that page.')

    user = login
    visit unread_posts_path

    aggregate_failures do
      expect(page).to have_selector('.table-title', text: 'Unread Posts')
      expect(page).to have_text('No posts yet')
      expect(page).to have_no_selector('.flash.error')
    end

    create_list(:post, 2)
    3.times do
      unread = Timecop.freeze(1.day.ago) do
        unread = create(:post)
        unread.mark_read(user)
        unread
      end
      create(:reply, user: unread.user, post: unread)
    end
    4.times do
      read = create(:post)
      read.mark_read(user)
    end

    visit unread_posts_path

    aggregate_failures do
      expect(page).to have_selector('.post-subject', count: 5)
      expect(page).to have_xpath("//img[contains(@src, 'note')]")
    end

    user.update!(layout: 'starrydark')
    click_link "Opened Threads »"

    aggregate_failures do
      expect(page).to have_selector('.post-subject', count: 3)
      expect(page).to have_xpath("//img[contains(@src, 'bullet')]")
    end
  end

  scenario "check-all checkbox works", :js do
    login
    visit unread_posts_path

    aggregate_failures do
      expect(page).to have_selector('.table-title', text: 'Unread Posts')
      expect(page).to have_no_selector('.check-all')
      expect(page).to have_no_selector('.check-all-item[name="marked_ids[]"]')
    end

    create_list(:post, 2)
    visit unread_posts_path

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
