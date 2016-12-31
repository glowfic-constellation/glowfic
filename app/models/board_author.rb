class BoardAuthor < ActiveRecord::Base
  belongs_to :board
  belongs_to :user

  validates :user_id, uniqueness: { scope: :board_id }
end
