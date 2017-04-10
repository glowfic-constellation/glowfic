Given(/^there is a board "(.*)" with (\d+) posts?$/) do |name, count|
  board = create(:board, name: name)
  count.to_i.times { create(:post, board: board, user: board.creator) }
end
