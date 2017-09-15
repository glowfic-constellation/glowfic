class AddOrderToGalleries < ActiveRecord::Migration[4.2]
  def up
    add_column :characters_galleries, :section_order, :integer, null: false, default: 0
    Character.all.each do |character|
      next unless character.galleries.present?
      next if character.galleries.count < 2
      character.galleries.sort_by(&:name).each_with_index do |gallery, index|
        character_gallery = CharactersGallery.where(gallery_id: gallery.id, character_id: character.id).first
        next unless character_gallery
        next if character_gallery.section_order == index
        character_gallery.update_attributes(section_order: index)
      end
    end
  end

  def down
    remove_column :characters_galleries, :section_order
  end
end
