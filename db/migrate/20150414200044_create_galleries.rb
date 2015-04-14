class CreateGalleries < ActiveRecord::Migration
  def change
    create_table :galleries do |t|
      t.integer :user_id, :null => false
      t.string :name, :null => false
      t.integer :cover_icon_id
      t.timestamps
    end
  end
end
