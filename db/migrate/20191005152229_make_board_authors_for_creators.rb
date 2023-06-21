class MakeBoardAuthorsForCreators < ActiveRecord::Migration[5.2]
  def up
    ids = Continuity.pluck(:creator_id, :id).map{ |i| { user_id: i[0], board_id: i[1] } }
    Continuity::Author.create!(ids)
  end

  def down
    boards = Continuity.joins(:continuity_authors).where('boards.creator_id = board_authors.user_id')
    Continuity::Author.where(id: boards.pluck('board_authors.id')).destroy_all
  end
end
