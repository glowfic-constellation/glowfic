RSpec.describe "Reply permalinks" do
  let(:user) { create(:user) }
  let(:post) { create(:post) }
  let!(:replies) do
    (1..12).map { |i| Timecop.freeze(post.created_at + i.minutes) { create(:reply, post: post) } }
  end

  before(:each) { login(user) }

  scenario "Permalink to a reply ahead of the reader's position" do
    target = replies[10]

    visit reply_path(target, anchor: "reply-#{target.id}", per_page: 5)

    within(".post-container:has(#reply-#{target.id})") do
      expect(page).to have_selector('.permalink-read-notice', text: 'Your reading position on this thread is earlier than this page')
      expect(page).to have_link('(Go to your reading position)')
      expect(page).to have_link('Mark as read up to here')
    end
    expect(post.reload.first_unread_for(user)).to eq(post) # still fully unread, untouched
  end

  scenario "Clicking 'Mark as read up to here' updates the reading position", :js do
    target = replies[10]

    visit reply_path(target, anchor: "reply-#{target.id}", per_page: 5)
    click_link 'Mark as read up to here'

    expect(page).to have_selector('.table-title', text: 'Unread Posts')
    expect(post.reload.first_unread_for(user)).to eq(target)
  end

  scenario "Permalink to a reply the reader has already read past" do
    Timecop.freeze(replies.last.created_at + 30.seconds) { post.mark_read(user) }
    target = replies[1]

    visit reply_path(target, anchor: "reply-#{target.id}", per_page: 5)

    within(".post-container:has(#reply-#{target.id})") do
      expect(page).to have_selector('.permalink-read-notice', text: 'You have already read further in this thread than this page')
      expect(page).to have_link('(Go to your reading position)')
      expect(page).to have_no_link('Mark as read up to here')
    end
    expect(post.reload.last_read(user)).to be_the_same_time_as(replies.last.created_at + 30.seconds)
  end

  scenario "Permalink matching the reader's position shows no notice" do
    target = replies[0]

    visit reply_path(target, anchor: "reply-#{target.id}", per_page: 5)

    expect(page).to have_selector('.content-header', text: post.subject)
    expect(page).to have_no_selector('.permalink-read-notice')
    expect(post.reload.last_read(user)).not_to be_nil
  end

  scenario "Notice can be dismissed", :js do
    target = replies[10]

    visit reply_path(target, anchor: "reply-#{target.id}", per_page: 5)
    expect(page).to have_selector('.permalink-read-notice')

    within('.permalink-read-notice') { find('.flash-dismiss').click }

    expect(page).to have_no_selector('.permalink-read-notice', wait: 2)
  end
end
