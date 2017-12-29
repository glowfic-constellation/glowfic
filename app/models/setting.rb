class Setting < ApplicationRecord
  belongs_to :user, optional: false

  has_many :post_settings, dependent: :destroy, inverse_of: :setting
  has_many :posts, through: :post_settings
  has_many :character_settings, dependent: :destroy, inverse_of: :setting
  has_many :characters, through: :character_settings

  has_many :parent_setting_tags, class_name: TagTag, foreign_key: :tag_id, inverse_of: :child_setting, dependent: :destroy
  has_many :child_setting_tags, class_name: TagTag, foreign_key: :tagged_id, inverse_of: :parent_setting, dependent: :destroy

  has_many :parent_settings, -> { order('tag_tags.id ASC') }, class_name: Setting, through: :child_setting_tags, source: :parent_setting
  has_many :child_settings, class_name: Setting, through: :parent_setting_tags, source: :child_setting

  validates_presence_of :name

  scope :with_item_counts, -> {
    select('(SELECT COUNT(DISTINCT post_settings.post_id) FROM post_settings WHERE post_settings.setting_id = settings.id) AS post_count,
      (SELECT COUNT(DISTINCT tag_tags.tagged_id) FROM tag_tags WHERE tag_tags.tag_id = settings.id) AS settings_count,
      (SELECT COUNT(DISTINCT character_settings.character_id) FROM character_settings WHERE character_settings.setting_id = settings.id) AS character_count')
  }

  def post_count
    return read_attribute(:post_count) if has_attribute?(:post_count)
    posts.count
  end

  def character_count
    return read_attribute(:character_count) if has_attribute?(:character_count)
    characters.count
  end

  def settings_count
    return read_attribute(:settings_count) if has_attribute?(:settings_count)
    child_settings.count
  end

  def has_items?
    post_count + character_count + settings_count > 0
  end

  def as_json(options={})
    {id: self.id, text: self.name}
  end

  def id_for_select
    return id if persisted? # id present on unpersisted records when associated record is invalid
    "_#{name}"
  end

    def editable_by?(user)
    return false unless user
    return true if deletable_by?(user)
    return true if user.has_permission?(:edit_tags)
    !owned?
  end

  def deletable_by?(user)
    return false unless user
    return true if user.has_permission?(:delete_tags)
    user.id == user_id
  end
end
