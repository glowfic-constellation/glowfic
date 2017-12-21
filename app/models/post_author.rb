class PostAuthor < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false

  validates :user_id, uniqueness: { scope: :board_id }
end
