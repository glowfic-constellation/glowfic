require "spec_helper"

RSpec.describe Board do
  it "should allow everyone to post if open to anyone" do
    board = create(:board)
    user = create(:user)
    expect(board.open_to_anyone?).to be true
    expect(user.writes_in?(board)).to be true
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
    cameo = create(:user)
    board.board_authors.create(user: coauthor)
    board.board_authors.create(user: coauthor)
    board2.board_authors.create(user: coauthor)
    board.reload
    board2.reload
    expect(board.board_authors.count).to eq(1)
    expect(board2.board_authors.count).to eq(1)
  end

  it "should be fixable via admin method" do
    board = create(:board)
    post = create(:post, board: board)
    post2 = create(:post, board: board)
    post3 = create(:post, board: board)
    post4 = create(:post, board: board)
    post.update_attribute(:section_order, 2)
    expect(board.posts.order('section_order asc').pluck(:section_order)).to eq([1, 2, 2, 3])
    board.send(:fix_ordering)
    expect(board.posts.order('section_order asc').pluck(:section_order)).to eq([0, 1, 2, 3])
  end
end
