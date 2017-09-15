class MakeViewsUnique < ActiveRecord::Migration[4.2]
  def change
    remove_index :board_views, column: [:user_id, :board_id]
    add_index :board_views, [:user_id, :board_id], unique: true

    remove_index :post_views, column: [:user_id, :post_id]
    add_index :post_views, [:user_id, :post_id], unique: true
  end
end
