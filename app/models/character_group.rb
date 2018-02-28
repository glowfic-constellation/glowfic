class CharacterGroup < ApplicationRecord
  has_many :characters, dependent: :nullify
  has_many :templates, dependent: :nullify
  belongs_to :user, optional: false
  validates :name, presence: true
end
