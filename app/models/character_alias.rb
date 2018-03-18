class CharacterAlias < ApplicationRecord
  belongs_to :character, optional: false
  validates :name, presence: true
  after_destroy :clear_alias_ids

  scope :ordered, -> { order('lower(name) asc', created_at: :asc, id: :asc) }

  def as_json(_options={})
    { id: id, name: name }
  end

  private

  def clear_alias_ids
    ReplyDraft.where(character_alias_id: id).update_all(character_alias_id: nil)
    UpdateModelJob.perform_later(Reply.to_s, {character_alias_id: id}, {character_alias_id: nil})
    UpdateModelJob.perform_later(Post.to_s, {character_alias_id: id}, {character_alias_id: nil})
  end
end
