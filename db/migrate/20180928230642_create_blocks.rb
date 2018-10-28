class CreateBlocks < ActiveRecord::Migration[5.1]
  def change
    create_table :blocks do |t|
      t.integer :blocking_user_id, null: false
      t.integer :blocked_user_id, null: false
      t.boolean :block_interactions, default: true
      t.integer :hide_them, default: 0
      t.integer :hide_me, default: 0

      t.timestamps
    end

    add_index :blocks, :blocking_user_id
    add_index :blocks, :blocked_user_id
  end
end
