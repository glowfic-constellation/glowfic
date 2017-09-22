class CreateFavorites < ActiveRecord::Migration[4.2]
  def up
    create_table :favorites do |t|
      t.integer :user_id, null: false
      t.integer :favorite_id, null: false
      t.string :favorite_type, null: false
      t.timestamps null: true
    end
    add_index :favorites, :user_id
    add_index :favorites, [:favorite_id, :favorite_type]
  end

  def down
    drop_table :favorites
  end
end
