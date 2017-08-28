class GalleryTag < ActiveRecord::Base
  belongs_to :gallery, inverse_of: :gallery_tags
  belongs_to :tag
  belongs_to :gallery_group, foreign_key: :tag_id

  after_create :add_gallery_to_characters
  after_destroy :remove_gallery_from_characters

  def add_gallery_to_characters
    return if gallery_group.nil? # skip non-gallery_groups
    joined_characters = gallery_group.characters.joins(:characters_galleries).where(characters_galleries: {gallery_id: gallery.id})
    characters = gallery_group.characters.where(user_id: gallery.user_id).where.not(id: joined_characters.pluck(:id))
    characters.each do |character|
      CharactersGallery.create(character_id: character.id, gallery_id: gallery.id, added_by_group: true)
    end
  end

  def remove_gallery_from_characters
    return if gallery_group.nil? # skip non-gallery_groups
    gallery.remove_gallery_from_characters(gallery_group)
  end
end
