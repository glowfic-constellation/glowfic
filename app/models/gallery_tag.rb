class GalleryTag < ApplicationRecord
  belongs_to :gallery, inverse_of: :gallery_tags, optional: false
  belongs_to :tag, inverse_of: :gallery_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :gallery_group, foreign_key: :tag_id, inverse_of: :gallery_tags, optional: false # This is currently required but may not continue to be

  after_create :add_gallery_to_characters
  after_destroy :remove_gallery_from_characters

  def add_gallery_to_characters
    return if gallery_group.nil? # skip non-gallery_groups
    characters = gallery_group.characters.where(user_id: gallery.user_id).pluck(:id)
    characters -= gallery.characters_galleries.pluck(:character_id) # skip characters that already have joins
    characters.each do |character_id|
      gallery.characters_galleries.create(character_id: character_id, added_by_group: true)
    end
  end

  def remove_gallery_from_characters
    return if gallery_group.nil? # skip non-gallery_groups

    gallery_group.characters.each do |character|
      next if character.gallery_groups.where.not(id: gallery_group.id).collect(&:galleries).include?(gallery) # skip if the gallery is in another attached group
      cg = character.character_gallery_for(gallery)
      next unless cg.added_by_group? # skip anchored galleries
      cg.destroy!
    end
  end
end
