class CreateReplyDrafts < ActiveRecord::Migration[4.2]
  def change
    create_table :reply_drafts do |t|
      t.integer :post_id, :null => false
      t.integer :user_id, :null => false
      t.text :content
      t.integer :character_id
      t.integer :icon_id
      t.integer :thread_id
      t.timestamps null: true
    end
    add_index :reply_drafts, [:post_id, :user_id]
    add_column :users, :default_editor, :string, default: 'rtf'
  end
end
