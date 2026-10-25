class CreateReplies < ActiveRecord::Migration[4.2]
  def change
    create_table :replies do |t|
      t.integer :post_id, null: false
      t.integer :user_id, null: false
      t.text :content, null: false
      t.integer :character_id
      t.integer :icon_id
      t.integer :thread_id
      t.timestamps null: true
    end
    add_index :replies, :post_id
    add_index :replies, :user_id
    add_index :replies, :character_id
    add_index :replies, :icon_id
    add_index :replies, :thread_id
  end
end
