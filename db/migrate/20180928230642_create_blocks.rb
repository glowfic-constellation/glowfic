class CreateBlocks < ActiveRecord::Migration[5.1]
  def change
    create_table :blocks do |t|
      t.integer :blocking_user_id, null: false
      t.integer :blocked_user_id, null: false
      t.boolean :block_interactions, default: true
      t.boolean :hide_their_posts, default: false
      t.boolean :hide_their_content, default: false
      t.boolean :hide_my_content, default: false

      t.timestamps
    end
  end
end
