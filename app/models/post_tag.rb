class PostTag < ApplicationRecord
  belongs_to :post, inverse_of: :post_tags, optional: false
  belongs_to :user, optional: false
  belongs_to :tag, optional: false
  belongs_to :setting, foreign_key: :tag_id, optional: true
  belongs_to :content_warning, foreign_key: :tag_id, optional: true
  belongs_to :label, foreign_key: :tag_id, optional: true
end
