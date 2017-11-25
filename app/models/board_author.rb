class BoardAuthor < ApplicationRecord
  belongs_to :board, optional: false
  belongs_to :user, optional: false

  validates :user_id, uniqueness: { scope: :board_id }
end
