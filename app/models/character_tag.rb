class CharacterTag < ApplicationRecord
  belongs_to :character, inverse_of: :character_tags
  belongs_to :tag
  belongs_to :label, foreign_key: :tag_id
  belongs_to :setting, foreign_key: :tag_id
  belongs_to :gallery_group, foreign_key: :tag_id
  belongs_to :canon, foreign_key: :tag_id
  validates_presence_of :character

  after_create :add_galleries_to_character
  after_destroy :remove_galleries_from_character

  def add_galleries_to_character
    return if gallery_group.nil? # skip non-gallery_groups
    joined_galleries = gallery_group.galleries.where(id: character.characters_galleries.map(&:gallery_id))
    galleries = gallery_group.galleries.where(user_id: character.user_id).where.not(id: joined_galleries.pluck(:id))
    galleries.each do |gallery|
      character.characters_galleries.create(gallery_id: gallery.id, added_by_group: true)
    end
  end

  def remove_galleries_from_character
    return if gallery_group.nil? # skip non-gallery_groups
    galleries = gallery_group.galleries.where(user_id: character.user_id)
    joined_group_galleries = character.gallery_groups.joins(:galleries).where(galleries: {user_id: character.user_id}).pluck(:gallery_id)
    galleries = galleries.where.not(id: joined_group_galleries)
    character.characters_galleries.where(gallery: galleries, added_by_group: true).destroy_all
    character.characters_galleries.reload
  end
end
