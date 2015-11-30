class CharacterGroup < ActiveRecord::Base
  has_many :characters
  belongs_to :user
  validates_presence_of :name, :user
end
