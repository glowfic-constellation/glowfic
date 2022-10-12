class BoardView < ApplicationRecord
  self.table_name = 'continuity_views'

  belongs_to :board, foreign_key: :continuity_id, inverse_of: :views, optional: false
  belongs_to :user, optional: false

  alias_attribute :board_id, :continuity_id

  validates :board, uniqueness: { scope: :user }
end
