class CreateBoardAuthors < ActiveRecord::Migration[4.2]
  def up
    create_table :board_authors do |t|
      t.integer :user_id, null: false
      t.integer :board_id, null: false
      t.timestamps null: true
    end
    add_index :board_authors, :board_id
    add_index :board_authors, :user_id
    Board.all.each do |board|
      next unless board.coauthor_id.present?
      BoardAuthor.create!(board_id: board.id, user_id: board.coauthor_id)
    end
    remove_column :boards, :coauthor_id
  end

  def down
    add_column :boards, :coauthor_id, :integer
    add_index :boards, :coauthor_id
    BoardAuthor.all.each do |author|
      author.board.coauthor_id = author.user_id
      author.board.save!
    end
    drop_table :board_authors
  end
end
