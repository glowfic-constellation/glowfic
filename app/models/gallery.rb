class Gallery < ActiveRecord::Base
  include Taggable
  belongs_to :user

  has_many :galleries_icons, dependent: :destroy
  accepts_nested_attributes_for :galleries_icons, allow_destroy: true
  has_many :icons, -> { order('LOWER(keyword)') }, through: :galleries_icons

  has_many :characters_galleries, inverse_of: :gallery
  has_many :characters, through: :characters_galleries

  has_many :gallery_tags, inverse_of: :gallery, dependent: :destroy
  has_many :gallery_groups, through: :gallery_tags, source: :gallery_group, after_remove: :remove_gallery_from_characters

  validates_presence_of :user, :name

  acts_as_tag :gallery_group

  scope :ordered, -> { order('characters_galleries.section_order ASC') }
  scope :with_icon_count, -> {
    joins('LEFT JOIN galleries_icons ON galleries.id = galleries_icons.gallery_id')
      .select("galleries.*, count(galleries_icons.id) as icon_count")
      .group("galleries.id")
  }
  scope :with_gallery_groups, -> {
    # fetches an array of
    # galleries.map(&:gallery_groups).map{|group| [f1: group.id, f2: group.name]}
    # ordered by tag name
    select("ARRAY(SELECT row_to_json(ROW(tags.id, tags.name)) FROM tags LEFT JOIN gallery_tags ON gallery_tags.tag_id = tags.id WHERE gallery_tags.gallery_id = galleries.id AND tags.type = 'GalleryGroup') AS gallery_groups_data_internal")
  }

  # Converts the internal [{'f1' => id, 'f2' => name}] structure of the retrieved data
  # to [{id => id, name => name}]
  def gallery_groups_data
    return @gallery_groups_data unless @gallery_groups_data.nil?
    if has_attribute?(:gallery_groups_data_internal)
      data_internal = read_attribute(:gallery_groups_data_internal)
      faked = Struct.new(:id, :name)
      @gallery_groups_data = gallery_groups_data_internal.map do |old|
        faked.new(old['f1'], old['f2'])
      end
    else
      @gallery_groups_data = gallery_groups
    end
    @gallery_groups_data
  end

  def character_gallery_for(character)
    characters_galleries.where(character_id: character).first
  end

  def remove_gallery_from_characters(gallery_group)
    characters = gallery_group.characters.where(user_id: user_id)
    CharactersGallery.where(character: characters, gallery: self, added_by_group: true).destroy_all
  end
end
