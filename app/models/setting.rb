# frozen_string_literal: true
class Setting < Tag
  has_many :parent_setting_tags, class_name: 'Tag::SettingTag', foreign_key: :tag_id, inverse_of: :parent_setting, dependent: :destroy
  has_many :child_setting_tags, class_name: 'Tag::SettingTag', foreign_key: :tagged_id, inverse_of: :child_setting, dependent: :destroy

  has_many :parent_settings, -> { ordered_by_tag_tag }, class_name: 'Setting', through: :child_setting_tags,
    source: :parent_setting, dependent: :destroy
  has_many :child_settings, class_name: 'Setting', through: :parent_setting_tags, source: :child_setting, dependent: :destroy

  def merge_with(other_tag)
    super do
      # rubocop:disable Rails/SkipsModelValidations
      their_characters = CharacterTag.where(tag: other_tag)
      their_characters.where(character_id: character_ids).delete_all
      their_characters.update_all(tag_id: self.id)

      their_children = Tag::SettingTag.where(tag_id: other_tag.id)
      their_children.where(tagged_id: child_setting_ids).delete_all
      their_children.update_all(tag_id: self.id)
      their_parents = Tag::SettingTag.where(tagged_id: other_tag.id)
      their_parents.where(tag_id: parent_setting_ids).delete_all
      their_parents.update_all(tagged_id: self.id)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
