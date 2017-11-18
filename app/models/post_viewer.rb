class PostViewer < ApplicationRecord
  belongs_to :post, optional: false
  belongs_to :user, optional: false
end
