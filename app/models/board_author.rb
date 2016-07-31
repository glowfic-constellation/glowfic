class BoardAuthor < ActiveRecord::Base
  belongs_to :board
  belongs_to :user

  validates :user_id, uniqueness: { scope: :board_id }

  default_scope where(cameo: false)
  scope :cameo, where(cameo: true)
end
