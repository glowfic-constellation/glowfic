RSpec.describe "Wrangling tags" do
  scenario "A wrangler works through their queue" do
    wrangler = create(:wrangler_user, username: 'wrangler')
    setting = create(:setting, name: 'Sample Setting')
    create(:wrangling_assignment, user: wrangler, setting: setting)

    duplicate = create(:label, name: 'Bar Fight')
    variant = create(:label, name: 'bar fights')
    create(:post, settings: [setting], labels: [duplicate])
    create(:post, settings: [setting], labels: [variant])

    login(wrangler)
    visit tag_wranglings_path

    expect(page).to have_text('Tag Wrangling')
    expect(page).to have_text('taggings use a canonical tag')

    within('table', text: 'Candidate Duplicates') do
      expect(page).to have_link('Bar Fight')
      expect(page).to have_link('bar fights')
    end

    within(table_titled('Unreviewed Tags')) do
      within('tr', text: 'Bar Fight', match: :prefer_exact) { click_button 'Mark canonical' }
    end

    expect(page).to have_text('Tag Bar Fight marked canonical.')
    expect(duplicate.reload).to be_canonical
  end

  scenario "A wrangler merges a duplicate into its canonical form" do
    wrangler = create(:wrangler_user)
    setting = create(:setting)
    create(:wrangling_assignment, user: wrangler, setting: setting)

    keeper = create(:label, name: 'Keeper')
    loser = create(:label, name: 'Looser')
    create(:post, settings: [setting], labels: [keeper])
    tagged_post = create(:post, settings: [setting], labels: [loser])

    login(wrangler)
    visit tag_wranglings_path

    within(table_titled('Unreviewed Tags')) do
      row = find('tr', text: 'Looser')
      within(row) do
        fill_in 'merger_id', with: keeper.id
        click_button 'Merge'
      end
    end

    expect(page).to have_text('Tag Looser is now a synonym of Keeper.')
    expect(loser.reload.merger).to eq(keeper)
    expect(tagged_post.reload.labels).to eq([keeper])
  end

  scenario "An ordinary user cannot reach the queue" do
    login
    visit tag_wranglings_path

    expect(page).to have_text('You do not have permission to wrangle tags.')
  end
end
