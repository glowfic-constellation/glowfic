class Setting < Tag
  include Taggable

  has_many :parent_setting_tags, class_name: TagTag, foreign_key: :tag_id, inverse_of: :child_setting
  has_many :child_setting_tags, class_name: TagTag, foreign_key: :tagged_id, inverse_of: :parent_setting

  has_many :parent_settings, class_name: Setting, through: :child_setting_tags, source: :parent_setting
  has_many :child_settings, class_name: Setting, through: :parent_setting_tags, source: :child_setting

  acts_as_tag :parent_setting, klass: Setting

  def has_items?
    return true if super
    child_settings.count > 0
  end
end
