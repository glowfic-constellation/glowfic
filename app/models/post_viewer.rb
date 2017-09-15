class PostViewer < ApplicationRecord
  belongs_to :post
  belongs_to :user

  validates_presence_of :user, :post
end
