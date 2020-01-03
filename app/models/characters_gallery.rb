class CharactersGallery < ApplicationRecord
  belongs_to :character, inverse_of: :characters_galleries, optional: false
  belongs_to :gallery, inverse_of: :characters_galleries, optional: false

  before_validation :override_groups
  before_create :autofill_order
  after_destroy :check_for_groups, :reorder_others

  validates :character, uniqueness: { scope: :gallery }

  scope :ordered, -> { order(section_order: :asc) }

  def reorder_others
    character.reorder_galleries
  end

  def autofill_order
    self.section_order = CharactersGallery.where(character_id: character_id).count
  end

  def override_groups
    return if added_by_group?
    CharactersGallery.find_by(character_id: character_id, gallery_id: gallery_id, added_by_group: true)&.destroy
  end

  def check_for_groups
    return if added_by_group?
    return unless (character.gallery_groups & gallery.gallery_groups).present?
    CharactersGallery.create!(character_id: character_id, gallery_id: gallery_id, added_by_group: true, section_order: section_order)
  end
end
