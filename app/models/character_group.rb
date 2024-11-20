# frozen_string_literal: true
class CharacterGroup < ApplicationRecord
  has_many :characters, dependent: :nullify
  belongs_to :user, optional: false
  validates :name, presence: true, length: { maximum: 255 }
end
