# frozen_string_literal: true
class Setting < Tag
  # Confirmed edges only, so the hierarchy shown in the editor matches the one
  # traversal walks.
  has_many :parent_setting_tags, -> { confirmed }, class_name: 'Tag::MetaTag', foreign_key: :tag_id,
    inverse_of: :parent_setting, dependent: :destroy
  has_many :child_setting_tags, -> { confirmed }, class_name: 'Tag::MetaTag', foreign_key: :tagged_id,
    inverse_of: :child_setting, dependent: :destroy

  has_many :parent_settings, -> { ordered_by_tag_tag }, class_name: 'Setting', through: :child_setting_tags,
    source: :parent_setting, dependent: :destroy
  has_many :child_settings, class_name: 'Setting', through: :parent_setting_tags, source: :child_setting, dependent: :destroy

  has_many :wrangling_assignments, inverse_of: :setting, dependent: :destroy
  has_many :wranglers, through: :wrangling_assignments, source: :user

  def descendant_ids
    Tag::MetaTag.descendant_ids_of(self)
  end

  def ancestor_ids
    Tag::MetaTag.ancestor_ids_of(self)
  end
end
