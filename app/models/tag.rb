class Tag < ActsAsTaggableOn::Tag
  has_many :post_tags, inverse_of: :tag, dependent: false
  has_many :character_tags, inverse_of: :tag, dependent: false
  has_many :gallery_tags, inverse_of: :tag, dependent: false

  has_many :child_taggings, class_name: 'ActsAsTaggableOn::Tagging', dependent: :destroy

  has_many :owners, through: :child_taggings, source: :taggable, source_type: 'User', dependent: :destroy
  has_many :posts, through: :child_taggings, source: :taggable, source_type: "Post", dependent: :destroy
  has_many :characters, through: :child_taggings, source: :taggable, source_type: "Character", dependent: :destroy

  TYPES = %w(ContentWarning Label Setting GalleryGroup)

  validates :type, presence: true
  validates :name, uniqueness: { scope: :type }

  scope :ordered_by_type, -> { order(type: :desc, name: :asc) }

  scope :ordered_by_name, -> { order(name: :asc) }

  scope :ordered_by_id, -> { order(id: :asc) }

  scope :ordered_by_tagging, -> { order('tagging.created_at ASC') }

  # rubocop:disable Style/TrailingCommaInArguments
  scope :with_character_counts, -> {
    select(
      <<~SQL
        (SELECT COUNT(DISTINCT taggings.taggable_id) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.taggable_type = 'Character') AS character_count
      SQL
    )
  }
  # rubocop:enable Style/TrailingCommaInArguments

  def editable_by?(user)
    return false unless user
    return true if deletable_by?(user)
    return true if user.has_permission?(:edit_tags)
    return false unless is_a?(Setting)
    !owners.exists?
  end

  def deletable_by?(user)
    return false unless user
    return true if user.has_permission?(:delete_tags)
    owner_ids.include?(user.id)
  end

  def as_json(options={})
    tag_json = {id: self.id, text: self.name}
    return tag_json unless options[:include].present?
    if options[:include].include?(:gallery_ids)
      g_tags = ActsAsTaggableOn::Tagging.where(taggable_type: 'Gallery').joins('INNER JOIN galleries ON galleries.id = taggings.taggable_id')
      g_tags = g_tags.where(galleries: {user_id: options[:user_id]}) if options[:user_id].present?
      tag_json[:gallery_ids] = g_tags.pluck('galleries.id')
    end
    tag_json
  end

  def post_count
    return read_attribute(:post_count) if has_attribute?(:post_count)
    posts.count
  end

  def character_count
    return read_attribute(:character_count) if has_attribute?(:character_count)
    characters.count
  end

  def merge_with(other_tag)
    return false unless type == other_tag.type
    transaction do
      unless type == GalleryGroup.to_s
        theirs = ActsAsTaggableOn::Tagging.where(tag: other_tag, taggable_type: 'Post')
        theirs.where(taggable_id: post_ids).delete_all
        theirs.update_all(tag_id: self.id)
      end
      if [GalleryGroup, Setting].map(&:to_s).include?(type)
        theirs = ActsAsTaggableOn::Tagging.where(tag: other_tag, taggable_type: 'Character')
        theirs.where(taggable_id: character_ids).delete_all
        theirs.update_all(tag_id: self.id)
      end
      if type == GalleryGroup.to_s
        theirs = ActsAsTaggableOn::Tagging.where(tag: other_tag, taggable_type: 'Gallery')
        theirs.where(taggable_id: gallery_ids).delete_all
        theirs.update_all(tag_id: self.id)
      end
      if type == Setting.to_s
        their_children = ActsAsTaggableOn::Tagging.where(tag: other_tag, taggable_type: 'ActsAsTaggableOn::Tag')
        their_children.where(taggable_id: child_ids).delete_all
        their_children.update_all(tag_id: self.id)
        their_parents = ActsAsTaggableOn::Tagging.where(taggable: other_tag, taggable_type: 'ActsAsTaggableOn::Tag')
        their_parents.where(tag_id: parent_ids).delete_all
        their_parents.update_all(taggable_id: self.id)
      end
      other_tag.destroy!
    end
  end

  # AATO overrides
  def self.for_context(context)
    where(type: context.classify)
  end

  def self.find_or_create_all_with_like_by_name(*list)
    list = Array(list).flatten

    return [] if list.empty?

    list.map do |tag_name|
      existing_tag = self.find_by(name: tag_name)
      existing_tag || create!(name: tag_name)
    end
  end

  private

  # disables the AATO unscoped uniqueness validation
  def validates_name_uniqueness?
    false
  end
end
