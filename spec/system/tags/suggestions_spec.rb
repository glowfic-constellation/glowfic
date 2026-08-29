RSpec.describe "Suggesting tags" do
  def relogin_as(user)
    page.driver.submit :delete, logout_path, {}
    login(user)
  end

  scenario "A reader suggests a tag and the author accepts it" do
    author = create(:user, username: 'author')
    reader = create(:user, username: 'reader')
    post = create(:post, user: author, subject: 'Sample post')
    tag = create(:label, name: 'Bar Fight')

    login(reader)
    visit stats_post_path(post)
    click_link 'Suggest a tag'

    select 'Label', from: 'tag_suggestion_tag_type'
    fill_in 'tag_suggestion_tag_name', with: 'Bar Fight'
    fill_in 'tag_suggestion_note', with: 'There is a bar fight in chapter two.'
    click_button 'Suggest'

    expect(page).to have_text('Suggestion recorded. The post author will review it.')

    relogin_as(author)
    visit tag_suggestions_path

    row = find('tr', text: 'Bar Fight')
    within(row) do
      expect(page).to have_text('reader')
      expect(page).to have_text('There is a bar fight in chapter two.')
      click_button 'Apply'
    end

    expect(page).to have_text('Tag Bar Fight applied.')
    expect(post.reload.labels).to eq([tag])
  end

  scenario "A declined tag cannot be suggested again until the author allows it" do
    author = create(:user)
    reader = create(:user)
    other_reader = create(:user)
    post = create(:post, user: author)
    tag = create(:label, name: 'Declined')
    suggestion = TagSuggestion.create!(post: post, user: reader, tag: tag)

    login(author)
    visit tag_suggestions_path
    within('tr', text: 'Declined') { click_button 'Decline' }
    expect(page).to have_text('It cannot be suggested on this post again.')

    relogin_as(other_reader)
    expect {
      TagSuggestion.submit(post: post, user: other_reader, tag: tag)
    }.not_to change { TagSuggestion.count }

    relogin_as(author)
    visit tag_suggestions_path
    within('tr', text: 'Declined') { click_button 'Permit again' }
    expect(page).to have_text('may be suggested again')
    expect(TagSuggestion.find_by(id: suggestion.id)).to be_nil
  end

  scenario "An author sees an endorsement rather than a duplicate suggestion" do
    author = create(:user)
    reader = create(:user)
    post = create(:post, user: author)
    create_list(:reply, 3, post: post, user: author)
    tag = create(:label, name: 'Hidden Twist')
    PostTag.create!(post: post, tag: tag, spoiler: true, reveal_after_reply_order: 3)

    # The reader has not read far enough to see the tagging, so their suggestion
    # must not reveal that it already exists.
    TagSuggestion.submit(post: post, user: reader, tag: tag)

    login(author)
    visit tag_suggestions_path

    within('table', text: 'Endorsements') do
      expect(page).to have_text('Hidden Twist')
    end
    expect(page).to have_text('No action is required')
  end

  scenario "A spoiler tag stays collapsed until the reader reveals it" do
    author = create(:user)
    reader = create(:user)
    post = create(:post, user: author)
    replies = create_list(:reply, 3, post: post, user: author)
    tag = create(:label, name: 'Late Reveal')
    PostTag.create!(post: post, tag: tag, spoiler: true, reveal_after_reply_order: replies.last.reply_order)

    login(reader)
    visit stats_post_path(post)

    expect(page).to have_selector('details.spoiler-tags')
    expect(page).to have_text('1 spoiler tag')
    expect(page).to have_no_selector('details.spoiler-tags[open]')

    # The name is present in the document but not displayed until expanded.
    find('details.spoiler-tags summary').click
    expect(page).to have_link('Late Reveal')
    expect(page).to have_text("from reply #{replies.last.reply_order}")
  end

  scenario "A reader who opts in sees spoiler tags already expanded" do
    author = create(:user)
    reader = create(:user, reveal_spoiler_tags: true)
    post = create(:post, user: author)
    tag = create(:label, name: 'Opted In')
    PostTag.create!(post: post, tag: tag, spoiler: true)

    login(reader)
    visit stats_post_path(post)

    expect(page).to have_link('Opted In')
    expect(page).to have_no_selector('details.spoiler-tags')
  end
end
