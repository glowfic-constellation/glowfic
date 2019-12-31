class Gallery < ApplicationRecord
  belongs_to :user, optional: false

  has_many :galleries_icons, dependent: :destroy, inverse_of: :gallery
  accepts_nested_attributes_for :galleries_icons, allow_destroy: true
  has_many :icons, -> { ordered }, through: :galleries_icons, dependent: :destroy

  has_many :characters_galleries, inverse_of: :gallery, dependent: :destroy
  has_many :characters, through: :characters_galleries, dependent: :destroy

  has_many :gallery_tags, inverse_of: :gallery

  validates :name, presence: true

  before_save :update_characters

  scope :ordered, -> { order('characters_galleries.section_order ASC') }

  scope :ordered_by_name, -> { order(Arel.sql('lower(name) asc'), id: :asc) }

  scope :ordered_by_id, -> { order(id: :asc) }

  scope :with_icon_count, -> {
    joins('LEFT JOIN galleries_icons ON galleries.id = galleries_icons.gallery_id')
      .select("galleries.*, count(galleries_icons.id) as icon_count")
      .group("galleries.id")
  }

  # rubocop:disable Style/TrailingCommaInArguments
  scope :with_gallery_groups, -> {
    # fetches an array of
    # galleries.map(&:gallery_groups).map{|group| [f1: group.id, f2: group.name]}
    # ordered by tag name
    select(
      <<~SQL
        ARRAY(
          SELECT row_to_json(ROW(tags.id, tags.name)) FROM tags
          LEFT JOIN taggings ON taggings.tag_id = tags.id
          WHERE taggings.taggable_id = galleries.id AND taggings.taggable_type = 'Gallery' AND tags.type = 'GalleryGroup'
          ORDER BY taggings.created_at ASC
        ) AS gallery_groups_data_internal
      SQL
    )
  }
  # rubocop:enable Style/TrailingCommaInArguments

  acts_as_ordered_taggable_on :gallery_groups

  # Converts the internal [{'f1' => id, 'f2' => name}] structure of the retrieved data
  # to [{id => id, name => name}]
  def gallery_groups_data
    return @gallery_groups_data unless @gallery_groups_data.nil?
    if has_attribute?(:gallery_groups_data_internal)
      data_internal = read_attribute(:gallery_groups_data_internal)
      faked = Struct.new(:id, :name)
      @gallery_groups_data = data_internal.map do |old|
        faked.new(old['f1'], old['f2'])
      end
    else
      @gallery_groups_data = gallery_groups
    end
    @gallery_groups_data
  end

  def character_gallery_for(character)
    characters_galleries.find_by(character_id: character)
  end

  private

  def update_characters
    return unless gallery_group_list_changed?

    present_characters = ActsAsTaggableOn::Tagging.where(taggable_type: 'Character').joins(:tag)
    present_characters = present_characters.joins("INNER JOIN characters ON characters.id = taggings.taggable_id")
    present_characters = present_characters.where(tags: {type: 'GalleryGroup', name: gallery_group_list})
    present_characters = present_characters.where(characters: {user_id: user_id}).pluck(:taggable_id)

    if new_record? || gallery_group_list_was.nil?
      add_characters_from_group(present_characters)
    else
      add_characters_from_group(present_characters) unless (gallery_group_list - gallery_group_list_was).empty?
      remove_characters_from_group(present_characters) unless (gallery_group_list_was - gallery_group_list).empty?
    end
  end

  def add_characters_from_group(present_characters)
    existing_links = characters_galleries.select(:character_id)
    new_characters = Character.where(id: present_characters).where.not(id: existing_links)
    new_characters.each do |character|
      creates = {character: character, added_by_group: true}
      if new_record?
        characters_galleries.new(creates)
      else
        characters_galleries.create!(creates)
      end
    end
  end

  def remove_characters_from_group(present_characters)
    rem_cgs = characters_galleries.where(added_by_group: true)
    rem_cgs = rem_cgs.where.not(character_id: present_characters) if gallery_group_list.present?
    rem_cgs.destroy_all
  end
end
