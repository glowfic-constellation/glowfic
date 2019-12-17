class AddAuthorsLockedToBoards < ActiveRecord::Migration[5.2]
  def up
    add_column :boards, :authors_locked, :boolean, default: true
    locked_boards = BoardAuthor.select(:board_id).distinct.pluck(:board_id)
    Board.where.not(id: locked_boards).update_all(authors_locked: false)

    rename_column :indexes, :open_to_anyone, :authors_locked
    change_column_default :indexes, :authors_locked, true
    Index.all.each { |index| index.update(authors_locked: !index.authors_locked) }
  end

  def down
    remove_column :boards, :authors_locked, :boolean
    Index.all.each { |index| index.update(authors_locked: !index.authors_locked) }
    change_column_default :indexes, :authors_locked, false
    rename_column :indexes, :authors_locked, :open_to_anyone
  end
end
