require "spec_helper"

RSpec.feature "Show a single continuity", :type => :feature do
  scenario "View a standard continuity" do
    board = create(:board, name: "Test board")
    5.times do create(:post, board: board, user: board.creator) end

    visit board_path(board)

    expect(page).to have_text("Test board")
    expect(page).to have_selector('.post-subject', count: 5)
  end

  scenario "View a continuity with many authors in a post" do
    board = create(:board, name: "Author board")
    post1 = create(:post, board: board, user: board.creator)
    reply = create(:reply, post: post1)
    post2 = create(:post, board: board, user: board.creator)
    4.times do create(:reply, post: post2) end

    visit board_path(board)

    expect(page).to have_text("Author board")
    expect(page).to have_selector('.post-subject', count: 2)
    within("tbody tr:nth-child(2)") do
      expect(page).to have_selector('.post-subject', text: post1.subject)
      expect(page).to have_selector('.post-authors', text: /#{reply.user.username}/)
    end
    within("tbody tr:nth-child(1)") do
      expect(page).to have_selector('.post-subject', text: post2.subject)
      expect(page).to have_selector('.post-authors', text: /and 4 others/)
    end
  end
end
