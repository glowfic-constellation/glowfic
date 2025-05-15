RSpec.describe "View blocks list" do
  scenario 'Viewing a blocks list', :aggregate_failures do
    user = create(:user, username: 'Jane Doe')
    blocked1 = create(:user, username: 'Alice')
    blocked2 = create(:user, username: 'Bob')
    blocked3 = create(:user, username: 'Carol')
    create(:block, blocking_user: user, blocked_user: blocked1, block_interactions: true, hide_them: :posts)
    create(:block, blocking_user: user, blocked_user: blocked2, block_interactions: false, hide_me: :posts)
    create(:block, blocking_user: user, blocked_user: blocked3, block_interactions: true, hide_them: :posts, hide_me: :all)
    login(user)
    visit blocks_path

    warn_text = "Warning: full blocking is not yet implemented, and will function the same as simply blocking posts. Additionally, any threads not locked to their authors will not be covered by post blocking." # rubocop:disable Layout/LineLength
    expect(page).to have_selector('.flash.error', text: warn_text)
    expect(page).to have_selector('.table-title', text: 'Blocked Users')
    expect(page).to have_selector('.link-box.action-new', text: '+ Block User')

    within('tbody') do
      expect(first('tr')).to have_text('Alice Yes Posts None')
      expect(all('tr')[1]).to have_text('Bob No None Posts')
      expect(all('tr')[2]).to have_text('Carol Yes Posts All')
    end
  end
end
