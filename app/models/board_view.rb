class BoardView < ApplicationRecord
  belongs_to :board, optional: false
  belongs_to :user, optional: false

  alias_attribute :continuity_id, :board_id

  validates :board, uniqueness: { scope: :user }
end
