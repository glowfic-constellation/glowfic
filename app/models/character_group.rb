class CharacterGroup < ApplicationRecord
  has_many :characters, dependent: :nullify
  belongs_to :user, optional: false
  validates :name, presence: true
end
