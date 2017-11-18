class CharacterGroup < ApplicationRecord
  has_many :characters
  has_many :templates
  belongs_to :user, optional: false
  validates_presence_of :name
end
