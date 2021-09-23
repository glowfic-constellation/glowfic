class BoardAuthor < ApplicationRecord
  self.table_name = 'continuity_authors'

  belongs_to :board, foreign_key: :continuity_id, inverse_of: :board_authors, optional: false
  belongs_to :user, optional: false

  alias_attribute :board_id, :continuity_id

  validates :user, uniqueness: { scope: :board }
end
