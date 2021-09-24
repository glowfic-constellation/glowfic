class BoardAuthor < ApplicationRecord
  belongs_to :continuity, class_name: 'Board', foreign_key: :board_id, inverse_of: :board_authors, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :continuity }
end
