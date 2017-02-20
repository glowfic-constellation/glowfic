class Gallery < ActiveRecord::Base
  belongs_to :user
  belongs_to :cover_icon, class_name: Icon
  has_and_belongs_to_many :icons, after_add: :set_has_gallery, after_remove: :unset_has_gallery
  has_and_belongs_to_many :ordered_icons, after_add: :set_has_gallery, after_remove: :unset_has_gallery, order: 'LOWER(keyword)', class_name: Icon

  has_many :characters_galleries
  has_many :characters, through: :characters_galleries

  accepts_nested_attributes_for :icons

  validates_presence_of :user, :name

  scope :ordered, -> { order('characters_galleries.section_order ASC') }

  def default_icon
    cover_icon || icons.first
  end

  def character_gallery_for(character)
    characters_galleries.where(character_id: character).first
  end

  private

  def set_has_gallery(icon)
    icon.update_attributes(has_gallery: true)
  end

  def unset_has_gallery(icon)
    return if icon.galleries.present?
    icon.update_attributes(has_gallery: false)
  end
end
