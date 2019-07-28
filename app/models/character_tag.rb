class CharacterTag < ApplicationRecord
  belongs_to :character, inverse_of: :character_tags, optional: false
  belongs_to :tag, inverse_of: :character_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :setting, foreign_key: :tag_id, inverse_of: :character_tags, optional: true
  belongs_to :gallery_group, foreign_key: :tag_id, inverse_of: :character_tags, optional: true

  after_create :add_galleries_to_character
  after_destroy :remove_galleries_from_character

  def add_galleries_to_character
    return if gallery_group.nil? # skip non-gallery_groups
    galleries = gallery_group.galleries.where(user_id: character.user_id).pluck(:id)
    galleries -= character.characters_galleries.pluck(:gallery_id) # skip galleries that already have joins
    galleries.each do |gallery_id|
      character.characters_galleries.create(gallery_id: gallery_id, added_by_group: true)
    end
  end

  def remove_galleries_from_character
    return if gallery_group.nil? # skip non-gallery_groups

    gallery_group.galleries.each do |gallery|
      next if (character.gallery_groups - [gallery_group]).collect(&:gallery_ids).flatten.include?(gallery.id) # skip if the gallery is in another attached group
      cg = character.character_gallery_for(gallery)
      next unless cg&.added_by_group? # skip anchored and unjoined galleries
      cg.destroy!
    end
  end
end
