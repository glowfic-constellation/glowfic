class CreateJoinTableIconGallery < ActiveRecord::Migration[4.2]
  def up
    create_table :galleries_icons do |t|
      t.integer :icon_id
      t.integer :gallery_id
    end
    add_index :galleries_icons, :icon_id
    add_index :galleries_icons, :gallery_id
  end

  def down
    drop_table :galleries_icons
  end
end
