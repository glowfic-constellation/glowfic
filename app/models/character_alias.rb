# frozen_string_literal: true
class CharacterAlias < ApplicationRecord
  belongs_to :character, optional: false
  has_many :reply_drafts, dependent: :nullify
  validates :name, presence: true, length: { maximum: 255 }
  after_destroy :clear_alias_ids

  scope :ordered, -> { order(Arel.sql('lower(name) asc'), created_at: :asc, id: :asc) }

  def as_json(_options={})
    { id: id, name: name }
  end

  private

  def clear_alias_ids
    UpdateModelJob.perform_later(Reply.to_s, { character_alias_id: id }, { character_alias_id: nil }, audited_user_id)
    UpdateModelJob.perform_later(Post.to_s, { character_alias_id: id }, { character_alias_id: nil }, audited_user_id)
  end
end
