class Gallery < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :icons
  has_many :characters
end
