class CreateFavorites < ActiveRecord::Migration
  def up
    create_table :favorites do |t|
      t.integer :user_id, null: false
      t.integer :favorite_id, null: false
      t.string :favorite_type, null: false
      t.timestamps
    end
    add_index :favorites, :user_id
    add_index :favorites, [:favorite_id, :favorite_type]
  end

  def down
    drop_table :favorites
  end
end
