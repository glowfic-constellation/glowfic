# frozen_string_literal: true
class Tag::MetaTag < ApplicationRecord
  self.table_name = 'tag_tags'

  belongs_to :child_tag, class_name: 'Tag', foreign_key: :tagged_id, inverse_of: :child_meta_tags, optional: true
  belongs_to :parent_tag, class_name: 'Tag', foreign_key: :tag_id, inverse_of: :parent_meta_tags, optional: true
  belongs_to :child_setting, class_name: 'Setting', foreign_key: :tagged_id, inverse_of: :child_setting_tags, optional: true
  belongs_to :parent_setting, class_name: 'Setting', foreign_key: :tag_id, inverse_of: :parent_setting_tags, optional: true

  scope :confirmed, -> { where(suggested: false) }
  scope :suggested, -> { where(suggested: true) }

  validates :child_tag, uniqueness: { scope: :parent_tag }
  validate :tags_share_a_type
  validate :edge_does_not_close_a_cycle

  # Written out per direction rather than interpolating column names, so no
  # identifier ever reaches the query as a substitution.
  ANCESTOR_SQL = <<~SQL.squish
    WITH RECURSIVE walk(id, path, cycle) AS (
      SELECT ?::integer, ARRAY[?::integer], false
      UNION ALL
      SELECT tag_tags.tag_id, walk.path || tag_tags.tag_id, tag_tags.tag_id = ANY(walk.path)
      FROM tag_tags
      JOIN walk ON tag_tags.tagged_id = walk.id
      WHERE NOT walk.cycle AND tag_tags.suggested = false
    )
    SELECT DISTINCT id FROM walk WHERE id != ?
  SQL

  DESCENDANT_SQL = <<~SQL.squish
    WITH RECURSIVE walk(id, path, cycle) AS (
      SELECT ?::integer, ARRAY[?::integer], false
      UNION ALL
      SELECT tag_tags.tagged_id, walk.path || tag_tags.tagged_id, tag_tags.tagged_id = ANY(walk.path)
      FROM tag_tags
      JOIN walk ON tag_tags.tag_id = walk.id
      WHERE NOT walk.cycle AND tag_tags.suggested = false
    )
    SELECT DISTINCT id FROM walk WHERE id != ?
  SQL

  # Includes suggested edges, so an edge that would close a cycle once
  # confirmed is rejected at the point it is proposed.
  ANCESTOR_ANY_SQL = <<~SQL.squish
    WITH RECURSIVE walk(id, path, cycle) AS (
      SELECT ?::integer, ARRAY[?::integer], false
      UNION ALL
      SELECT tag_tags.tag_id, walk.path || tag_tags.tag_id, tag_tags.tag_id = ANY(walk.path)
      FROM tag_tags
      JOIN walk ON tag_tags.tagged_id = walk.id
      WHERE NOT walk.cycle
    )
    SELECT DISTINCT id FROM walk WHERE id != ?
  SQL

  def self.ancestor_ids_of(tag)
    walk_ids(tag, ANCESTOR_SQL)
  end

  def self.any_ancestor_ids_of(tag)
    walk_ids(tag, ANCESTOR_ANY_SQL)
  end

  def self.descendant_ids_of(tag)
    walk_ids(tag, DESCENDANT_SQL)
  end

  # Cycle-safe: rows predating the cycle validation, or created by an import,
  # must not be able to hang the traversal.
  def self.walk_ids(tag, sql)
    return [] if tag.nil? || tag.id.nil?

    query = sanitize_sql_array([sql, tag.id, tag.id, tag.id])
    connection.select_values(query).map(&:to_i)
  end
  private_class_method :walk_ids

  private

  def tags_share_a_type
    return if child_tag.nil? || parent_tag.nil?
    return if child_tag.type == parent_tag.type
    errors.add(:base, "An implication requires both tags to be of the same type.")
  end

  def edge_does_not_close_a_cycle
    return if child_tag.nil? || parent_tag.nil?

    if child_tag == parent_tag
      errors.add(:base, "A tag cannot imply itself.")
      return
    end

    return unless Tag::MetaTag.any_ancestor_ids_of(parent_tag).include?(child_tag.id)
    errors.add(
      :base,
      "#{parent_tag.name} already implies #{child_tag.name}. This implication would create a cycle.",
    )
  end
end
