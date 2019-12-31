class BoardAuthor < ApplicationRecord
  belongs_to :board, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :board }
end
