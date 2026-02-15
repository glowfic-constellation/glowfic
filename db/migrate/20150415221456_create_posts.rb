class CreatePosts < ActiveRecord::Migration[4.2]
  def change
    create_table :posts do |t|
      t.integer :board_id, :null => false
      t.integer :user_id, :null => false
      t.string :subject, :null => false
      t.text :content, :null => false
      t.integer :character_id
      t.integer :icon_id
      t.integer :privacy, :null => false, :default => 0
      t.timestamps null: true
    end
    add_index :posts, :board_id
    add_index :posts, :user_id
    add_index :posts, :character_id
    add_index :posts, :icon_id
  end
end
