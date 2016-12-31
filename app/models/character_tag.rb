class CharacterTag < ActiveRecord::Base
  belongs_to :character, inverse_of: :character_tags
  belongs_to :all_tags, inverse_of: :character_tags, polymorphic: true, foreign_key: :tag_id
end
