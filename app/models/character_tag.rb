class CharacterTag < ActiveRecord::Base
  belongs_to :character, inverse_of: :character_tags
  belongs_to :tag
  belongs_to :label, foreign_key: :tag_id
  belongs_to :setting, foreign_key: :tag_id
  belongs_to :gallery_group, foreign_key: :tag_id
  validates_presence_of :character

  after_create :add_galleries_to_character
  after_destroy :remove_galleries_from_character

  def add_galleries_to_character
    return if gallery_group.nil? # skip non-gallery_groups
    joined_galleries = gallery_group.galleries.joins(:characters_galleries).where(characters_galleries: {character_id: character.id})
    galleries = gallery_group.galleries.where(user_id: character.user_id).where.not(id: joined_galleries.pluck(:id))
    galleries.each do |gallery|
      CharactersGallery.create(character_id: character.id, gallery_id: gallery.id, added_by_group: true)
      puts "Adding gallery #{gallery.id} to character #{character.id}"
    end
  end

  def remove_galleries_from_character
    puts "GOT REMOVED"
    return if gallery_group.nil? # skip non-gallery_groups
    galleries = gallery_group.galleries.where(user_id: character.user_id)
    CharactersGallery.where(character: character, gallery: galleries, added_by_group: true).destroy_all
  end
end
