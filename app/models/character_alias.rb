class CharacterAlias < ApplicationRecord
  belongs_to :character, optional: false
  validates_presence_of :name
  after_destroy :clear_alias_ids

  def as_json(_options={})
    { id: id, name: name }
  end

  private

  def clear_alias_ids
    Reply.where(character_alias_id: id).update_all(character_alias_id: nil)
    Post.where(character_alias_id: id).update_all(character_alias_id: nil)
    ReplyDraft.where(character_alias_id: id).update_all(character_alias_id: nil)
  end
end
