# frozen_string_literal: true
class Tag < ApplicationRecord
  belongs_to :user, optional: false
  has_many :user_tags, dependent: :destroy, inverse_of: :tag
  has_many :users, through: :user_tags, dependent: :destroy
  has_many :post_tags, dependent: :destroy, inverse_of: :tag
  has_many :posts, through: :post_tags, dependent: :destroy
  has_many :character_tags, dependent: :destroy, inverse_of: :tag
  has_many :characters, through: :character_tags, dependent: :destroy
  has_many :gallery_tags, dependent: :destroy, inverse_of: :tag
  has_many :galleries, through: :gallery_tags, dependent: :destroy

  belongs_to :merger, class_name: 'Tag', optional: true, inverse_of: :mergers
  has_many :mergers, class_name: 'Tag', inverse_of: :merger, dependent: :nullify

  has_many :parent_meta_tags, class_name: 'Tag::MetaTag', inverse_of: :parent_tag, dependent: :destroy
  has_many :child_meta_tags, class_name: 'Tag::MetaTag', foreign_key: :tagged_id, inverse_of: :child_tag, dependent: :destroy

  TYPES = %w(Setting Label ContentWarning GalleryGroup)
  # GalleryGroup tags attach to galleries, not posts.
  POST_TYPES = %w(Setting Label ContentWarning)

  validates :name, :type, presence: true
  validates :name, uniqueness: { scope: :type }
  validate :merger_is_a_valid_synonym_target

  # `canonical` only records that a wrangler has reviewed the tag and must not
  # gate behaviour: search, filtering, autocomplete and display treat canonical
  # and non-canonical tags alike. See doc/rfcs/001-tag-wrangling.md.
  scope :wrangleable, -> { where(merger_id: nil, unwrangleable: false) }
  scope :awaiting_wrangling, -> { wrangleable.where(canonical: false) }

  # The tags a scoped wrangler may act on: their Settings, and any other tag
  # sharing a post with one of those Settings.
  scope :within_wrangling_scope, ->(setting_ids) {
    co_tagged = PostTag.where(post_id: PostTag.where(tag_id: setting_ids).select(:post_id)).select(:tag_id)
    where(id: setting_ids).or(where.not(type: 'Setting').where(id: co_tagged))
  }

  scope :ordered_by_type, -> { order(type: :desc, name: :asc) }

  scope :ordered_by_name, -> { order(name: :asc) }

  scope :ordered_by_id, -> { order(id: :asc) }

  scope :ordered_by_user_tag, -> { order('user_tags.id ASC') }

  scope :ordered_by_char_tag, -> { order('character_tags.id ASC') }

  scope :ordered_by_gallery_tag, -> { order('gallery_tags.id ASC') }

  scope :ordered_by_post_tag, -> { order('post_tags.id ASC') }

  scope :ordered_by_tag_tag, -> { order('tag_tags.id ASC') }

  scope :with_character_counts, -> {
    select("(SELECT COUNT(DISTINCT character_tags.character_id) FROM character_tags WHERE character_tags.tag_id = tags.id) AS character_count")
  }

  def editable_by?(user)
    return false unless user
    return true if deletable_by?(user)
    return true if user.has_permission?(:edit_tags)
    return true if wrangleable_by?(user)
    return false if user.read_only?
    return false unless is_a?(Setting)
    !owned?
  end

  def wrangleable_by?(user)
    return false unless user
    return true if user.has_permission?(:wrangle_tags_global)
    return false unless user.has_permission?(:wrangle_tags)

    setting_ids = user.wrangling_scope_ids
    return false if setting_ids.empty?
    return setting_ids.include?(id) if is_a?(Setting)
    Tag.within_wrangling_scope(setting_ids).exists?(id)
  end

  def deletable_by?(user)
    return false unless user
    return true if user.has_permission?(:delete_tags)
    user.id == user_id
  end

  def as_json(options={})
    tag_json = { id: self.id, text: self.name }
    return tag_json unless options[:include].present? && options[:include].include?(:gallery_ids)

    g_tags = gallery_tags.joins(:gallery)
    g_tags = g_tags.where(galleries: { user_id: options[:user_id] }) if options[:user_id].present?
    tag_json[:gallery_ids] = g_tags.pluck(:gallery_id).sort
    tag_json
  end

  def id_for_select
    return id if persisted? # id present on unpersisted records when associated record is invalid
    "_#{name}"
  end

  def user_count
    return read_attribute(:user_count) if has_attribute?(:user_count)
    users.count
  end

  def post_count
    return read_attribute(:post_count) if has_attribute?(:post_count)
    posts.count
  end

  def character_count
    return read_attribute(:character_count) if has_attribute?(:character_count)
    characters.count
  end

  # Posts listed under this tag. A spoiler tagging must not disclose its post
  # through the tag, so it is left out.
  def unspoilered_posts
    posts.where(post_tags: { spoiler: false })
  end

  def synonym?
    merger_id.present?
  end

  # Re-points every tagging onto this tag and leaves the loser as a synonym, so
  # links to it still resolve.
  def merge_as_synonym(other_tag)
    raise ArgumentError, "Cannot merge a tag into itself" if other_tag == self
    raise ArgumentError, "Cannot merge across tag types" if other_tag.type != type

    transaction do
      absorb_taggings_from(other_tag)
      # Re-pointing the loser's own synonyms keeps chains one level deep.
      Tag.where(merger_id: other_tag.id).update_all(merger_id: self.id) # rubocop:disable Rails/SkipsModelValidations
      WranglingAssignment.reassign_for_merge(source: other_tag, target: self) if is_a?(Setting)
      update!(canonical: true) unless canonical?
      other_tag.update!(merger_id: self.id, canonical: false)
    end
    self
  end

  # Destroys the loser rather than keeping it as a synonym; admin-only.
  def merge_with(other_tag)
    raise ArgumentError, "Cannot merge a tag into itself" if other_tag == self
    raise ArgumentError, "Cannot merge across tag types" if other_tag.type != type

    transaction do
      absorb_taggings_from(other_tag)
      WranglingAssignment.reassign_for_merge(source: other_tag, target: self) if is_a?(Setting)
      other_tag.destroy
    end
  end

  private

  # Drops rows that would collide with a tagging self already has.
  def absorb_taggings_from(other_tag)
    # rubocop:disable Rails/SkipsModelValidations
    UserTag.where(tag_id: other_tag.id).where(user_id: user_tags.select(:user_id).distinct.pluck(:user_id)).delete_all
    UserTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
    PostTag.where(tag_id: other_tag.id).where(post_id: post_tags.select(:post_id).distinct.pluck(:post_id)).delete_all
    PostTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
    CharacterTag.where(tag_id: other_tag.id).where(character_id: character_tags.select(:character_id).distinct.pluck(:character_id)).delete_all
    CharacterTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
    GalleryTag.where(tag_id: other_tag.id).where(gallery_id: gallery_tags.select(:gallery_id).distinct.pluck(:gallery_id)).delete_all
    GalleryTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
    Tag::MetaTag.where(tag_id: other_tag.id, tagged_id: self.id).delete_all
    Tag::MetaTag.where(tag_id: self.id, tagged_id: other_tag.id).delete_all
    Tag::MetaTag.where(tag_id: other_tag.id).update_all(tag_id: self.id)
    Tag::MetaTag.where(tagged_id: other_tag.id).update_all(tagged_id: self.id)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def merger_is_a_valid_synonym_target
    return if merger.nil?

    errors.add(:merger, "cannot be the tag itself") if merger_id == id
    errors.add(:merger, "must be the same type of tag") if merger.type != type
    errors.add(:merger, "must itself be canonical") unless merger.canonical?
    errors.add(:canonical, "cannot be set on a tag that is a synonym of another") if canonical?
  end
end
