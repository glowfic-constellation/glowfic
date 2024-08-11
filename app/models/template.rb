# frozen_string_literal: true
class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates, optional: false
  has_many :characters, -> { ordered }, inverse_of: :template, dependent: :nullify

  validates :name, presence: true

  scope :ordered, -> { order(name: :asc, created_at: :asc, id: :asc) }

  CHAR_PLUCK = Arel.sql("id, concat_ws(' | ', name, nickname, screenname)")
  NPC_PLUCK = Arel.sql("id, concat_ws(' | ', name, nickname)")

  def plucked_characters
    characters.non_npcs.where(retired: false).pluck(CHAR_PLUCK)
  end
end
