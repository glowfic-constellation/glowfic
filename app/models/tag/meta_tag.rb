# frozen_string_literal: true

# An implication edge between two tags of the same type: tagging the child
# implies the parent. Suggested edges are recorded but imply nothing.
class Tag::MetaTag < ApplicationRecord
  self.table_name = 'tag_tags'

  belongs_to :child_tag, class_name: 'Tag', foreign_key: :tagged_id, inverse_of: :child_meta_tags, optional: true
  belongs_to :parent_tag, class_name: 'Tag', foreign_key: :tag_id, inverse_of: :parent_meta_tags, optional: true
  belongs_to :child_setting, class_name: 'Setting', foreign_key: :tagged_id, inverse_of: :child_setting_tags, optional: true
  belongs_to :parent_setting, class_name: 'Setting', foreign_key: :tag_id, inverse_of: :parent_setting_tags, optional: true

  scope :confirmed, -> { where(suggested: false) }

  validates :child_tag, uniqueness: { scope: :parent_tag }
  validate :tags_share_a_type
  validate :edge_does_not_close_a_cycle

  # UNION rather than UNION ALL discards rows already visited, so the walk
  # terminates even on a cycle that predates the validation.
  DESCENDANTS_SQL = <<~SQL.squish
    WITH RECURSIVE walk(id) AS (
      SELECT unnest(ARRAY[?]::integer[])
      UNION
      SELECT tag_tags.tagged_id FROM tag_tags
      JOIN walk ON tag_tags.tag_id = walk.id
      WHERE ? OR NOT tag_tags.suggested
    )
    SELECT id FROM walk
  SQL

  # The given tag ids plus everything they imply downwards, in one query.
  def self.self_and_descendant_ids(tag_ids, include_suggested: false)
    tag_ids = Array(tag_ids)
    return [] if tag_ids.empty?
    connection.select_values(sanitize_sql_array([DESCENDANTS_SQL, tag_ids, include_suggested])).map(&:to_i)
  end

  private

  def tags_share_a_type
    return if child_tag.nil? || parent_tag.nil?
    return if child_tag.type == parent_tag.type
    errors.add(:base, "An implication requires both tags to be of the same type.")
  end

  # Checked against suggested edges too, so an edge that would close a cycle
  # once confirmed is rejected when it is proposed.
  def edge_does_not_close_a_cycle
    return if child_tag.nil? || parent_tag.nil?

    if child_tag == parent_tag
      errors.add(:base, "A tag cannot imply itself.")
      return
    end

    return unless Tag::MetaTag.self_and_descendant_ids(child_tag.id, include_suggested: true).include?(parent_tag.id)
    errors.add(:base, "#{parent_tag.name} already implies #{child_tag.name}. This implication would create a cycle.")
  end
end
