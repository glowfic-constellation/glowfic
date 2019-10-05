class MakeBoardAuthorsForCreators < ActiveRecord::Migration[5.2]
  def up
    ids = Board.pluck(:creator_id, :id).map{ |i| { user_id: i[0], board_id: i[1] } }
    BoardAuthor.create!(ids)
  end

  def down
    boards = Board.joins(:board_authors).where('boards.creator_id = board_authors.user_id')
    BoardAuthor.where(id: boards.pluck('board_authors.id')).destroy_all
  end
end
