class OldCharacterGroup < ApplicationRecord
  has_many :characters, dependent: :nullify
  belongs_to :user, optional: false
  validates :name, presence: true
  self.table_name = 'character_groups'
end
