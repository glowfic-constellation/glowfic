class Gallery < ActiveRecord::Base
  belongs_to :user
  belongs_to :cover_icon, class_name: Icon

  has_many :galleries_icons
  has_many :icons, -> { order('LOWER(keyword)') }, through: :galleries_icons

  has_many :characters_galleries
  has_many :characters, through: :characters_galleries

  accepts_nested_attributes_for :galleries_icons, allow_destroy: true

  validates_presence_of :user, :name

  scope :ordered, -> { order('characters_galleries.section_order ASC') }

  def default_icon
    cover_icon || icons.first
  end

  def character_gallery_for(character)
    characters_galleries.where(character_id: character).first
  end
end
