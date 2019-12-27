class PostTag < ApplicationRecord
  belongs_to :post, inverse_of: :post_tags, optional: false
  belongs_to :tag, inverse_of: :post_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :setting, foreign_key: :tag_id, inverse_of: :post_tags, optional: true
end
