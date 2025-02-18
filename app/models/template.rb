# frozen_string_literal: true
class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates, optional: false
  has_many :characters, -> { ordered }, inverse_of: :template, dependent: :nullify
  has_one :template_tag, class_name: 'Tag::TemplateTag', dependent: :destroy, inverse_of: :template
  has_one :character_group, through: :template_tag, dependent: :destroy

  validates :name, presence: true
  validate :valid_group

  scope :ordered, -> { order(name: :asc, created_at: :asc, id: :asc) }
  scope :ungrouped, -> { where("NOT EXISTS (SELECT 1 FROM template_tags WHERE template_tags.template_id = templates.id)") }

  CHAR_PLUCK = Arel.sql("characters.id as id, concat_ws(' | ', characters.name, nickname, screenname)")
  NPC_PLUCK = Arel.sql("characters.id as id, concat_ws(' | ', characters.name, nickname)")

  def plucked_characters
    characters.non_npcs.not_retired.pluck(CHAR_PLUCK)
  end

  private

  def valid_group
    return unless character_group.present?
    return if character_group.user_id == user_id
    errors.add(:character_group, "must be yours")
  end
end
