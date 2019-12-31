class PostAuthor < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false

  validates :user, uniqueness: { scope: :post }
end
