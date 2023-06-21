RSpec.feature "Show a single continuity", type: :feature do
  scenario "View a standard continuity" do
    continuity = create(:continuity, name: "Test continuity")
    create_list(:post, 5, board: continuity, user: continuity.creator)

    visit continuity_path(continuity)

    expect(page).to have_text("Test continuity")
    expect(page).to have_selector('.post-subject', count: 5)
  end

  scenario "View a continuity with many authors in a post" do
    continuity = create(:continuity, name: "Author continuity")
    post1 = create(:post, board: continuity, user: continuity.creator)
    reply = create(:reply, post: post1)
    post2 = create(:post, board: continuity, user: continuity.creator)
    create_list(:reply, 4, post: post2)

    visit continuity_path(continuity)

    expect(page).to have_text("Author continuity")
    expect(page).to have_selector('.post-subject', count: 2)
    within("tbody tr:nth-child(2)") do
      expect(page).to have_selector('.post-subject', exact_text: post1.subject)
      expect(page).to have_selector('.post-authors', text: reply.user.username)
    end
    within("tbody tr:nth-child(1)") do
      expect(page).to have_selector('.post-subject', exact_text: post2.subject)
      expect(page).to have_selector('.post-authors', text: 'and 4 others')
    end
  end

  scenario "View a continuity with deleted users" do
    del_user1 = create(:user, username: "John Doe")
    del_user2 = create(:user, username: "Jane Doe")
    coauthor1 = create(:user, username: "Alice")
    coauthor2 = create(:user, username: "Bob")
    coauthor3 = create(:user, username: "Poe")
    continuity = create(:continuity, name: "Test continuity")
    post1 = create(:post, user: del_user1, board: continuity)
    create(:reply, post: post1, user: coauthor3)
    post2 = create(:post, user: del_user2, board: continuity)
    post3 = create(:post, user: del_user2, board: continuity, authors: [del_user1, del_user2, coauthor1, coauthor2, coauthor3])
    create(:reply, post: post3, user: coauthor2)
    post4 = create(:post, user: coauthor1, board: continuity, authors: [del_user2, coauthor1, coauthor3])
    [coauthor1, coauthor3, del_user2].each { |u| create(:reply, post: post4, user: u) }
    del_user1.archive
    del_user2.archive

    visit continuity_path(continuity)

    expect(page).to have_text("Test continuity")
    expect(page).to have_selector('.post-subject', count: 4)
    within("tbody tr:nth-child(4)") do
      expect(page).to have_selector('.post-subject', exact_text: post1.subject)
      expect(page).to have_selector('.post-authors', text: 'Poe and 1 deleted user')
      expect(page).to have_selector('.post-time', text: 'Poe')
    end
    within("tbody tr:nth-child(3)") do
      expect(page).to have_selector('.post-subject', exact_text: post2.subject)
      expect(page).to have_selector('.post-authors', text: '(deleted user)')
      expect(page).to have_selector('.post-time', text: '(deleted user)')
    end
    within("tbody tr:nth-child(2)") do
      expect(page).to have_selector('.post-subject', exact_text: post3.subject)
      expect(page).to have_selector('.post-authors', text: 'Alice and 4 others')
      expect(page).to have_selector('.post-time', text: 'Bob')
    end
    within("tbody tr:nth-child(1)") do
      expect(page).to have_selector('.post-subject', exact_text: post4.subject)
      expect(page).to have_selector('.post-authors', text: 'Alice, Poe and 1 deleted user')
      expect(page).to have_selector('.post-time', text: '(deleted user)')
    end
  end
end
