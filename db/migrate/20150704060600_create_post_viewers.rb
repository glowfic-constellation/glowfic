class CreatePostViewers < ActiveRecord::Migration
  def change
    create_table :post_viewers do |t|
      t.integer :post_id, :null => false
      t.integer :user_id, :null => false
      t.timestamps
    end
    add_index :post_viewers, :post_id
  end
end
