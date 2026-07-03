class CreateSkins < ActiveRecord::Migration[8.0]
  def change
    create_table :skins do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.text :description
      t.text :css
      t.text :sanitized_css
      t.boolean :public, null: false, default: false
      t.timestamps
    end
    add_index :skins, :user_id
    add_index :skins, :public
  end
end
