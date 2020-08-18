class PostLink < ApplicationRecord
  belongs_to :linking_post, inverse_of: :linked_post_joins, optional: false
  belongs_to :linked_post, class_name: 'Post', inverse_of: :linking_post_joins, optional: false

  validates :post, uniqueness: { scope: :linked_post }
end
