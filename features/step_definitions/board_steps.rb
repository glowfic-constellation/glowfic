Given(/^there is a board "(.*)"$/) do |name|
  board = create(:board, name: name)
end

Given(/^there is a board "(.*)" with (\d+) posts?$/) do |name, count|
  board = create(:board, name: name)
  count.to_i.times { create(:post, board: board, user: board.creator) }
end

Given(/^there is a post "(.*)" in "(.*)" with (\d+) authors?$/) do |post_name, board_name, author_count|
  board = Board.where(name: board_name).first
  post = create(:post, subject: post_name, board: board)
  (author_count.to_i - 1).times { create(:reply, post: post) }
end
