class PostLink < ApplicationRecord
  belongs_to :linking_post, class_name: 'Post', inverse_of: :linked_post_joins, optional: false
  belongs_to :linked_post, class_name: 'Post', inverse_of: :linking_post_joins, optional: false

  validates :linking_post, uniqueness: { scope: :linked_post }

  TYPES = ['inspired by', 'an AU of', 'a sequel to', 'cocurrent with']
end
