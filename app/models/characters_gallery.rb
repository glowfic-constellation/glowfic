class CharactersGallery < ActiveRecord::Base
  belongs_to :character
  belongs_to :gallery

  before_create :autofill_order
  after_destroy :reorder_others

  def reorder_others
    others = CharactersGallery.where(character_id: character_id_was).order('section_order asc')
    return unless others.present?

    others.each_with_index do |other, index|
      next if other.section_order == index
      other.section_order = index
      other.save
    end
  end

  def autofill_order
    self.section_order = CharactersGallery.where(character_id: character_id).count
  end
end
