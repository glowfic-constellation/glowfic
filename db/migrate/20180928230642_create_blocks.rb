class CreateBlocks < ActiveRecord::Migration[5.1]
  def up
    create_table :blocks do |t|
      t.integer :blocking_user
      t.integer :blocked_user
      t.boolean :no_interact
      t.boolean :no_posts
      t.boolean :no_content
      t.boolean :invisible

      t.timestamps
    end
  end

  def down
    drop_table :blocks
  end
end
