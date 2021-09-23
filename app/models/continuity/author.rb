class Continuity::Author < ApplicationRecord
  belongs_to :continuity, foreign_key: :board_id, inverse_of: :continuity_authors, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :continuity }
end
