class CreateBoardView < ActiveRecord::Migration[4.2]
  def change
    create_table :board_views do |t|
      t.integer :board_id, null: false
      t.integer :user_id, null: false
      t.boolean :ignored, default: false
      t.boolean :notify_message, default: false
      t.boolean :notify_email, default: false
      t.timestamps null: true
    end
    add_index :board_views, [:user_id, :board_id]
  end
end
