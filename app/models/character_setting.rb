class CharacterSetting < ApplicationRecord
  belongs_to :character, optional: false
  belongs_to :setting, optional: false
end
