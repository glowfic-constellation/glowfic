class CreateJoinTableIconGallery < ActiveRecord::Migration
  def up
    create_table :galleries_icons do |t|
      t.integer :icon_id
      t.integer :gallery_id
    end
  end

  def down
    drop_table :galleries_icons
  end
end
