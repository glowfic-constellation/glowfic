class Template < ApplicationRecord
  include Presentable

  belongs_to :user, inverse_of: :templates, optional: false
  has_many :characters, -> { ordered }, inverse_of: :template, dependent: :nullify

  validates :name, presence: true

  scope :ordered, -> { order(name: :asc, created_at: :asc, id: :asc) }

  CHAR_PLUCK = Arel.sql("id, concat_ws(' | ', name, nickname, screenname)")
  NPC_PLUCK = Arel.sql("id, concat_ws(' | ', name)") # TODO: recent threads?

  def plucked_characters
    characters.where(retired: false, is_npc: false).pluck(CHAR_PLUCK)
  end
end
