class PostView < ActiveRecord::Base
  belongs_to :post
  belongs_to :user

  validates_presence_of :user, :post

  def timestamp_attributes_for_create
    super + [:read_at]
  end
end
