class CreatePostView < ActiveRecord::Migration[4.2]
  def change
    create_table :post_views do |t|
      t.integer :post_id, null: false
      t.integer :user_id, null: false
      t.boolean :ignored, default: false
      t.boolean :notify_message, default: false
      t.boolean :notify_email, default: false
      t.timestamps null: true
    end
    add_index :post_views, [:user_id, :post_id]
  end
end
