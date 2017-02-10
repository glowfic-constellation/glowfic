class CharacterAlias < ActiveRecord::Base
  belongs_to :character
  validates_presence_of :character, :name

  def as_json(options={})
    { id: id, name: name }
  end
end
