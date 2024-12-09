class AddUserTags < ActiveRecord::Migration[7.2]
  def change
    create_table :user_tags do |t|
      t.integer :user_id, null: false
      t.integer :tag_id, null: false
      t.timestamps null: true
    end
    add_index :user_tags, :user_id
    add_index :user_tags, :tag_id
  end
end
