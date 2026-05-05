class UnifyPostBoards < ActiveRecord::Migration[8.0]
  def up
    create_table :post_boards do |t|
      t.integer :post_id, null: false
      t.integer :board_id, null: false
      t.integer :section_id
      t.integer :section_order
      t.boolean :is_main, null: false, default: false
      t.timestamps null: true
    end

    add_index :post_boards, [:post_id, :board_id], unique: true
    add_index :post_boards, [:board_id, :section_id, :section_order],
      name: "index_post_boards_on_board_section_order"
    add_index :post_boards, :post_id, unique: true,
      where: "is_main = TRUE",
      name: "index_post_boards_one_main_per_post"

    execute <<-SQL
INSERT INTO post_boards (post_id, board_id, section_id, section_order, is_main, created_at, updated_at)
SELECT id, board_id, section_id, section_order, TRUE, NOW(), NOW()
FROM posts;
    SQL

    remove_index :posts, name: "index_posts_on_board_id"
    remove_column :posts, :section_order
    remove_column :posts, :section_id
    remove_column :posts, :board_id
  end

  def down
    add_column :posts, :board_id, :integer
    add_column :posts, :section_id, :integer
    add_column :posts, :section_order, :integer
    add_index :posts, :board_id

    execute <<-SQL
UPDATE posts
SET board_id = pb.board_id,
    section_id = pb.section_id,
    section_order = pb.section_order
FROM post_boards pb
WHERE pb.post_id = posts.id AND pb.is_main = TRUE;
    SQL

    change_column_null :posts, :board_id, false
    drop_table :post_boards
  end
end
