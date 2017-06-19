class Gallery < ActiveRecord::Base
  belongs_to :user

  has_many :galleries_icons
  has_many :icons, -> { order('LOWER(keyword)') }, through: :galleries_icons

  has_many :characters_galleries
  has_many :characters, through: :characters_galleries

  accepts_nested_attributes_for :galleries_icons, allow_destroy: true

  validates_presence_of :user, :name

  scope :ordered, -> { order('characters_galleries.section_order ASC') }
  scope :with_icon_count, -> {
    joins('LEFT JOIN galleries_icons ON galleries.id = galleries_icons.gallery_id')
      .select("galleries.*, count(galleries_icons.id) as icon_count")
      .group("galleries.id")
  }

  def character_gallery_for(character)
    characters_galleries.where(character_id: character).first
  end
end
