RSpec.describe "Spoiler tags" do
  scenario "A spoiler tag stays collapsed until the reader reveals it" do
    post = create(:post)
    tag = create(:label, name: 'Late Reveal')
    PostTag.create!(post: post, tag: tag, spoiler: true, applies_from_reply_order: 3)

    login
    visit stats_post_path(post)

    expect(page).to have_text('1 spoiler tag')
    expect(page).to have_no_selector('details.spoiler-tags[open]')
    expect(page).to have_no_link('Late Reveal')

    find('details.spoiler-tags summary').click
    expect(page).to have_link('Late Reveal')
    expect(page).to have_text('from reply 3')
  end

  scenario "A reader who opts in sees spoiler tags already expanded" do
    post = create(:post)
    tag = create(:label, name: 'Opted In')
    PostTag.create!(post: post, tag: tag, spoiler: true)

    login(create(:user, reveal_spoiler_tags: true))
    visit stats_post_path(post)

    expect(page).to have_link('Opted In')
    expect(page).to have_no_selector('details.spoiler-tags')
  end
end
