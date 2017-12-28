class PostAuthor < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false
  belongs_to :invited_by, class_name: User, optional: true

  validates :user_id, uniqueness: { scope: :post_id }
end
