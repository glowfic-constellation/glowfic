class AddGalleryTags < ActiveRecord::Migration
  def change
    create_table :gallery_tags do |t|
      t.integer :gallery_id, null: false
      t.integer :tag_id, null: false
      t.timestamps null: true

      t.index :gallery_id
      t.index :tag_id
    end
  end
end
