class Setting < Tag
  include Tag::Taggable::Setting

  has_many :parent_setting_tags, class_name: 'Tag::SettingTag', foreign_key: :tag_id, inverse_of: :parent_setting, dependent: :destroy
  has_many :child_setting_tags, class_name: 'Tag::SettingTag', foreign_key: :tagged_id, inverse_of: :child_setting, dependent: :destroy

  has_many :parent_settings, -> { ordered_by_tag_tag }, class_name: 'Setting', through: :child_setting_tags,
    source: :parent_setting, dependent: :destroy
  has_many :child_settings, class_name: 'Setting', through: :parent_setting_tags, source: :child_setting, dependent: :destroy

  private

  def get_setting_tags
    Tag::List.new(parent_settings.map(&:name))
  end

  def save_setting_tags
    return unless setting_list_changed?
    save_tags(::Setting, new_list: @setting_list, old_list: setting_list_was, assoc: parent_settings, join: child_setting_tags)
  end
end
