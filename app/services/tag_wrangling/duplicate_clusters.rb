# frozen_string_literal: true

# Groups tags whose names collapse to the same normalized form. Computed and
# cached rather than stored in a column, so the normalization can be tuned
# without a migration.
class TagWrangling::DuplicateClusters
  CACHE_TTL = 15.minutes
  MAX_CLUSTERS = 25

  def initialize(type: nil)
    @type = type
  end

  def clusters
    @clusters ||= Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { build_clusters }
  end

  def self.normalize(name)
    name.to_s
      .downcase
      .gsub(/[^a-z0-9]+/, ' ')
      .strip
      .split
      .map { |word| word.sub(/(?<=.{3})(?:es|s)\z/, '') }
      .join(' ')
  end

  private

  def build_clusters
    scope = Tag.wrangleable
    scope = scope.where(type: @type) if @type

    grouped = scope.pluck(:id, :name, :type).group_by do |(_id, name, type)|
      [type, self.class.normalize(name)]
    end

    grouped
      .select { |_key, rows| rows.size > 1 }
      .first(MAX_CLUSTERS)
      .map do |(type, normalized), rows|
        {
          type: type,
          normalized: normalized,
          tag_ids: rows.map(&:first),
          names: rows.map { |row| row[1] },
        }
      end
  end

  def cache_key
    "tag_wrangling/duplicate_clusters/#{@type || 'all'}/#{Tag.maximum(:updated_at).to_i}/#{Tag.count}"
  end
end
