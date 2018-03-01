class CharacterGroup < ApplicationRecord
  has_many :characters
  has_many :templates
  belongs_to :user, optional: false
  validates :name, presence: true
end
