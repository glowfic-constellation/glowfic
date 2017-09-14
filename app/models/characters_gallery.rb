class CharactersGallery < ApplicationRecord
  belongs_to :character, inverse_of: :characters_galleries
  belongs_to :gallery, inverse_of: :characters_galleries
  validates_presence_of :character, :gallery

  before_create :autofill_order
  after_destroy :reorder_others

  def reorder_others
    character.reorder_galleries
  end

  def autofill_order
    self.section_order = CharactersGallery.where(character_id: character_id).count
  end
end
