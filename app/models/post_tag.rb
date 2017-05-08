class PostTag < ActiveRecord::Base
  belongs_to :post, inverse_of: :post_tags
  belongs_to :user
  belongs_to :tag
  belongs_to :setting, foreign_key: :tag_id
  belongs_to :content_warning, foreign_key: :tag_id
  belongs_to :label, foreign_key: :tag_id
end
