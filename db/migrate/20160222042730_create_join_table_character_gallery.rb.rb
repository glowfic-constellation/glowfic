class CreateJoinTableCharacterGallery < ActiveRecord::Migration[4.2]
  def change
    create_table :characters_galleries do |t|
      t.integer :character_id, null: false
      t.integer :gallery_id, null: false
    end
    add_index :characters_galleries, :character_id
    add_index :characters_galleries, :gallery_id

    Character.all.each do |character|
      next unless character.gallery_id.present?
      next unless character.gallery.present?
      character.galleries << character.gallery
    end
    remove_column :characters, :gallery_id
  end
end
