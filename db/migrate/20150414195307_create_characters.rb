class CreateCharacters < ActiveRecord::Migration[4.2]
  def change
    create_table :characters do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.string :template_name
      t.string :screenname
      t.integer :gallery_id
      t.integer :template_id
      t.integer :default_icon_id
      t.timestamps null: true
    end
    add_index :characters, :screenname, unique: true
    add_index :characters, :user_id
    add_index :characters, :template_id
  end
end
