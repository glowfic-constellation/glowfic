class PostViewer < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  validates_presence_of :user, :post
  attr_accessible :user, :user_id, :post, :post_id
end
