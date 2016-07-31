class CharacterTag < ActiveRecord::Base
  belongs_to :character, inverse_of: :character_tags
  belongs_to :tag, inverse_of: :character_tags
end
