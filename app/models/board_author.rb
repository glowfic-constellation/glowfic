class BoardAuthor < ApplicationRecord
  belongs_to :board, optional: false
  belongs_to :user, optional: false

  alias_attribute :continuity_id, :board_id

  validates :user, uniqueness: { scope: :board }
end
