class CreateUserDefaultViewers < ActiveRecord::Migration[7.2]
  def change
    create_table :user_default_viewers do |t|
      t.integer :user_id, null: false
      t.integer :viewer_id, null: false
      t.timestamps null: true
    end
    add_index :user_default_viewers, :user_id
    add_index :user_default_viewers, [:user_id, :viewer_id], unique: true
  end
end
