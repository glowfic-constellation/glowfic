class BoardAuthor < ApplicationRecord
  belongs_to :board, class_name: 'Continuity', inverse_of: :board_authors, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :board }
end
