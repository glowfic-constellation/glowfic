class ReplyHistory < ActiveRecord::Base
  belongs_to :character
  belongs_to :icon
  belongs_to :user
  belongs_to :post
  belongs_to :reply

  validates_presence_of :post, :user, :content
  attr_protected :id
end
