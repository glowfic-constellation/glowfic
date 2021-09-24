class BoardView < ApplicationRecord
  belongs_to :continuity, class_name: 'Board', foreign_key: :board_id, inverse_of: :views, optional: false
  belongs_to :user, optional: false

  validates :continuity, uniqueness: { scope: :user }
end
