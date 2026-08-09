RSpec.describe PostBoard do
  describe "validations" do
    it "requires a unique post and continuity pair" do
      post = create(:post)
      membership = post.post_boards.build(board: post.board)
      expect(membership).not_to be_valid
      expect(membership.errors[:post]).to be_present
    end

    it "requires the section to belong to the continuity" do
      post = create(:post)
      board = create(:board)
      section = create(:board_section, board: create(:board))
      membership = post.post_boards.build(board: board, section: section)
      expect(membership).not_to be_valid
      expect(membership.errors[:section]).to include("must belong to this continuity")
    end

    it "requires the post's author to be able to write in the continuity" do
      post = create(:post)
      locked = create(:board, authors_locked: true)
      membership = post.post_boards.build(board: locked)
      expect(membership).not_to be_valid
      expect(membership.errors[:board]).to be_present
    end

    it "allows the post's author as a continuity writer" do
      post = create(:post)
      board = create(:board, authors_locked: true, writers: [post.user])
      membership = post.post_boards.build(board: board)
      expect(membership).to be_valid
    end
  end

  describe "#sync_board_cameos" do
    it "adds the post's other authors as cameos on locked secondary continuities" do
      post = create(:post)
      coauthor = create(:reply, post: post).user
      board = create(:board, authors_locked: true, writers: [post.user])
      post.post_boards.create!(board: board)
      expect(board.board_authors.where(cameo: true).pluck(:user_id)).to include(coauthor.id)
    end

    it "does not add cameos to open continuities" do
      post = create(:post)
      coauthor = create(:reply, post: post).user
      board = create(:board)
      post.post_boards.create!(board: board)
      expect(board.board_authors.where(cameo: true).pluck(:user_id)).not_to include(coauthor.id)
    end
  end
end
