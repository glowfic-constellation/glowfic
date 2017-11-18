class BoardView < ApplicationRecord
  belongs_to :board, optional: false
  belongs_to :user, optional: false

  validates :board, uniqueness: { scope: :user }
end
