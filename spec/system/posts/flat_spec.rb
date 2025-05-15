RSpec.describe "Viewing flat posts", :aggregate_failures do
  scenario "User views a flat post" do
    user = login
    post = create(:post, user: user, subject: "test subject", content: "test content", editor_mode: 'html')

    GenerateFlatPostJob.perform_now(post.id)

    visit post_path(post, view: 'flat')
    expect(page).to have_selector('.post-container', count: 1)
    expect(page).to have_selector('.post-post', count: 1)
    expect(page).to have_selector('#post-title', exact_text: "test subject")
    expect(page).to have_selector('.post-content p', exact_text: 'test content')
  end
end
