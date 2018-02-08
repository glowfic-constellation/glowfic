require "spec_helper"

RSpec.describe Board do
  include ActiveJob::TestHelper

  it "should allow everyone to post if open to anyone" do
    board = create(:board)
    user = create(:user)
    expect(board.open_to_anyone?).to be true
    expect(user.writes_in?(board)).to be true
  end

  describe "coauthors" do
    it "should list the correct writers" do
      board = create(:board)
      coauthor = create(:user)
      cameo = create(:user)
      not_board = create(:user)
      board.board_authors.create!(user: coauthor)
      board.board_authors.create!(user: cameo, cameo: true)
      board.reload
      expect(board.writer_ids).to match_array([board.creator_id, coauthor.id])
      expect(board.writer_ids).to match_array(board.writers.map(&:id))
    end

    it "should allow coauthors and cameos to post" do
      board = create(:board)
      coauthor = create(:user)
      cameo = create(:user)
      board.board_authors.create!(user: coauthor)
      board.board_authors.create!(user: cameo, cameo: true)
      board.reload
      expect(board.open_to_anyone?).to be false
      expect(coauthor.writes_in?(board)).to be true
      expect(cameo.writes_in?(board)).to be true
    end

    it "should allow coauthors but not cameos to edit" do
      board = create(:board)
      coauthor = create(:user)
      cameo = create(:user)
      board.board_authors.create!(user: coauthor)
      board.board_authors.create!(user: cameo, cameo: true)
      board.reload
      expect(board.editable_by?(coauthor)).to be true
      expect(board.editable_by?(cameo)).to be false
    end

    it "should allow coauthors only once per board" do
      board = create(:board)
      board2 = create(:board)
      coauthor = create(:user)
      cameo = create(:user) # FIXME: unused
      board.board_authors.create(user: coauthor)
      board.board_authors.create(user: coauthor)
      board2.board_authors.create(user: coauthor)
      board.reload
      board2.reload
      expect(board.board_authors.count).to eq(1)
      expect(board2.board_authors.count).to eq(1)
    end
  end

  it "should be fixable via admin method" do
    board = create(:board)
    post = create(:post, board: board)
    post2 = create(:post, board: board)
    post3 = create(:post, board: board)
    post4 = create(:post, board: board)
    post.update_attribute(:section_order, 2)
    section = create(:board_section, board: board)
    section2 = create(:board_section, board: board)
    section3 = create(:board_section, board: board)
    section.update_attribute(:section_order, 6)
    expect(board.posts.order('section_order asc').pluck(:section_order)).to eq([1, 2, 2, 3])
    expect(board.board_sections.order('section_order asc').pluck(:section_order)).to eq([1, 2, 6])
    board.send(:fix_ordering)
    expect(board.posts.order('section_order asc').pluck(:section_order)).to eq([0, 1, 2, 3])
    expect(board.board_sections.order('section_order asc').pluck(:section_order)).to eq([0, 1, 2])
  end

  describe "#ordered?" do
    it "should be unordered for default board" do
      expect(create(:board).ordered?).to eq(false)
    end

    it "should be ordered if board is not open to anyone" do
      board = create(:board)
      board.update_attributes(coauthors: [create(:user)])
      expect(board.ordered?).to eq(true)
      board.update_attributes(coauthors: [])
      expect(board.ordered?).to eq(false)
      board.update_attributes(cameos: [create(:user)])
      expect(board.ordered?).to eq(true)
    end

    it "should be ordered if board has sections" do
      board = create(:board)
      create(:board_section, board: board)
      expect(board.ordered?).to eq(true)
    end
  end

  it "deletes sections but moves posts to sandboxes" do
    board = create(:board)
    sandbox = create(:board, id: 3)
    section = create(:board_section, board: board)
    post = create(:post, board: board, section: section)
    perform_enqueued_jobs(only: UpdateModelJob) do
      board.destroy
    end
    post.reload
    expect(post.board_id).to eq(3)
    expect(post.section).to be_nil
    expect(BoardSection.find_by_id(section.id)).to be_nil
  end
end
