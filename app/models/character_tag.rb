class CharacterTag < ActiveRecord::Base
  belongs_to :character, inverse_of: :character_tags
  belongs_to :tag
  belongs_to :label, foreign_key: :tag_id
  belongs_to :setting, foreign_key: :tag_id
end
