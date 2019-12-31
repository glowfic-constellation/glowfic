class Tag < ActsAsTaggableOn::Tag
  has_many :post_tags, inverse_of: :tag
  has_many :character_tags, inverse_of: :tag
  has_many :gallery_tags, inverse_of: :tag

  has_many :child_taggings, class_name: 'ActsAsTaggableOn::Tagging', dependent: :destroy

  has_many :owners, through: :child_taggings, source: :taggable, source_type: 'User', dependent: :destroy
  has_many :posts, through: :child_taggings, source: :taggable, source_type: "Post", dependent: :destroy
  has_many :characters, through: :child_taggings, source: :taggable, source_type: "Character", dependent: :destroy

  TYPES = %w(ContentWarning Label Setting GalleryGroup)

  validates :name, uniqueness: { scope: :type }

  scope :ordered_by_type, -> { order(type: :desc, name: :asc) }

  scope :ordered_by_name, -> { order(name: :asc) }

  scope :ordered_by_id, -> { order(id: :asc) }

  scope :ordered_by_tagging, -> { order('tagging.created_at ASC') }


  # rubocop:disable Style/TrailingCommaInArguments
  scope :with_item_counts, -> {
    select(
      <<~SQL
        (SELECT COUNT(DISTINCT taggings.taggable_id) FROM taggings WHERE taggings.tag_id = tags.id AND taggings.taggable_type = 'Post') AS post_count,
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

  def id_for_select
    return id if persisted? # id present on unpersisted records when associated record is invalid
    "_#{name}"
  end

  def post_count
    return read_attribute(:post_count) if has_attribute?(:post_count)
    posts.count
  end

  def character_count
    return read_attribute(:character_count) if has_attribute?(:character_count)
    characters.count
  end

  def gallery_count
    return read_attribute(:gallery_count) if has_attribute?(:gallery_count)
    galleries.count
  end

  def has_items?
    # TODO auto destroy when false, and also maybe fix with settings/canons
    post_count + character_count + gallery_count > 0
  end

  def merge_with(other_tag)
    transaction do
      PostTag.where(tag_id: other_tag.id).where(post_id: post_tags.select(:post_id).distinct.pluck(:post_id)).delete_all
      PostTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      CharacterTag.where(tag_id: other_tag.id).where(character_id: character_tags.select(:character_id).distinct.pluck(:character_id)).delete_all
      CharacterTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      GalleryTag.where(tag_id: other_tag.id).where(gallery_id: gallery_tags.select(:gallery_id).distinct.pluck(:gallery_id)).delete_all
      GalleryTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      TagTag.where(tag_id: other_tag.id, tagged_id: self.id).delete_all
      TagTag.where(tag_id: self.id, tagged_id: other_tag.id).delete_all
      TagTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
      TagTag.where(tagged_id: other_tag.id).update_all(tagged_id: self.id)
      other_tag.destroy
    end
  end

  # AATO overrides
  def self.for_context(context)
    where(type: context.classify)
  end

  # overrides the complicated thing AATO does because their column isn't citext
  def self.named(name)
    where(name: name)
  end

  def self.named_any(list)
    where(name: list)
  end

  def self.named_like(name)
    where('name LIKE ?', sanitize_sql_like(name))
  end

  def self.named_like_any(list)
    where('name LIKE ?', sanitize_sql_like(list))
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
