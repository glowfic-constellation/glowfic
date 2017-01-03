class FlatPost < ActiveRecord::Base
  belongs_to :post, inverse_of: :flat_post

  validates_presence_of :post
end
