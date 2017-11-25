class PostTag < ApplicationRecord
  belongs_to :post, inverse_of: :post_tags, optional: false
  belongs_to :tag, inverse_of: :post_tags, optional: true # TODO: This is required, fix bug around validation if it is set as such
  belongs_to :setting, foreign_key: :tag_id, optional: true
  belongs_to :content_warning, foreign_key: :tag_id, optional: true
  belongs_to :label, foreign_key: :tag_id, optional: true
end
