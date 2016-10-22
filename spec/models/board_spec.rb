require "spec_helper"

RSpec.describe Board do
  it "should allow coauthors and cameos to post" do
    board = create(:board)
    coauthor = create(:user)
    cameo = create(:user)
    board.board_authors.create!(user: coauthor)
    board.board_authors.create!(user: cameo, cameo: true)
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
    expect(board.board_authors.count).to eq(1)
    expect(board2.board_authors.count).to eq(1)
  end
end
