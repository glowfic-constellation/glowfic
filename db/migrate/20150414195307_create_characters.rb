class CreateCharacters < ActiveRecord::Migration
  def change
    create_table :characters do |t|
      t.integer :user_id, :null => false
      t.string :name
      t.integer :gallery_id
      t.integer :template_id
      t.timestamps
    end
  end
end
