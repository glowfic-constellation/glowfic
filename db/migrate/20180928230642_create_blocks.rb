class CreateBlocks < ActiveRecord::Migration[5.1]
  def change
    create_table :blocks do |t|
      t.integer :blocking_user_id, null: false
      t.integer :blocked_user_id, null: false
      t.boolean :no_interact, default: true
      t.boolean :no_posts, default: false
      t.boolean :no_content, default: false
      t.boolean :invisible, default: false

      t.timestamps
    end
  end
end
