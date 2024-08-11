class GalleryTag < ApplicationRecord
  belongs_to :gallery, inverse_of: :gallery_tags, optional: false
  belongs_to :tag, inverse_of: :gallery_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :gallery_group, foreign_key: :tag_id, inverse_of: :gallery_tags, optional: true
  belongs_to :facecast, foreign_key: :tag_id, inverse_of: :gallery_tags, optional: true

  validates :gallery, uniqueness: { scope: :tag }

  after_create :add_gallery_to_characters
  after_destroy :remove_gallery_from_characters

  def add_gallery_to_characters
    return if gallery_group.nil? # skip non-gallery_groups
    joined_characters = gallery_group.characters.where(id: gallery.characters_galleries.map(&:character_id))
    characters = gallery_group.characters.where(user_id: gallery.user_id).where.not(id: joined_characters.pluck(:id))
    characters.each do |character|
      gallery.characters_galleries.create(character_id: character.id, added_by_group: true)
    end
  end

  def remove_gallery_from_characters
    return if gallery_group.nil? # skip non-gallery_groups
    CharactersGallery.where(character: gallery.characters, gallery: gallery, added_by_group: true).destroy_all
  end
end
