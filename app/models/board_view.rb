class BoardView < ApplicationRecord
  belongs_to :board
  belongs_to :user

  validates_presence_of :user, :board
  validates :board, uniqueness: { scope: :user }
end
