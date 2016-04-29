class PostTag < ActiveRecord::Base
  belongs_to :post, inverse_of: :post_tags
  belongs_to :user
  belongs_to :tag
end
