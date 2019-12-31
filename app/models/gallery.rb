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
          LEFT JOIN taggings ON tagging.tag_id = tags.id
          WHERE tagging.taggable_id = galleries.id AND AND tagging.taggable_type = 'Gallery' AND tags.type = 'GalleryGroup'
          ORDER BY tagging.created_at ASC
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

    user_characters = Character.where(user: user)

    new_characters = user_characters.tagged_with(new_groups, any: true)
    new_characters = new_characters.tagged_with(gallery_group_list_was, exclude: true) if gallery_group_list_was.present?
    new_characters.each { |character| characters_galleries.create!(character: character, added_by_group: true) }

    rem_characters = user_characters.tagged_with(rem_groups, any: true)
    rem_characters = rem_characters.tagged_with(gallery_group_list, exclude: true) if gallery_group_list.present?
    characters_galleries.where(character: rem_characters, added_by_group: true).destroy_all
  end
end
