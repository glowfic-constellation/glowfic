class CharacterGroup < Tag
  validates :name, uniqueness: { scope: [:type, :user] }
end
