class AddUserBookmarks < ActiveRecord::Migration[7.2]
  def change
    create_table :user_bookmarks do |t|
      t.integer :user_id, null: false
      t.integer :reply_id, null: false
      t.integer :post_id, null: false
      t.string :name, null: true
      t.string :type, null: false, default: "reply_bookmark"
      t.timestamps null: true
    end
    add_index :user_bookmarks, :user_id
    add_index :user_bookmarks, :reply_id
    add_index :user_bookmarks, :post_id
    add_index :user_bookmarks, [:user_id, :reply_id, :type], unique: true
    add_index :user_bookmarks, [:post_id, :user_id]

    add_column :users, :public_bookmarks, :boolean, default: false
  end
end
