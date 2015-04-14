class Icon < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :url, :user
end
