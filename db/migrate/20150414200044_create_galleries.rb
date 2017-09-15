class CreateGalleries < ActiveRecord::Migration[4.2]
  def change
    create_table :galleries do |t|
      t.integer :user_id, :null => false
      t.string :name, :null => false
      t.integer :cover_icon_id
      t.timestamps null: true
    end
    add_index :galleries, :user_id
  end
end
