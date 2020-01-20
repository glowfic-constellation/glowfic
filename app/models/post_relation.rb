class PostRelation < ApplicationRecord
  belongs_to :relating_post, inverse_of: :post_relations, optional: false
  belongs_to :related_post, class_name: 'Post', inverse_of: :post_relations, optional: false

  validates :post, uniqueness: { scope: :related_post }
end
