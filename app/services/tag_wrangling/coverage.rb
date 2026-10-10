# frozen_string_literal: true

# Progress weighted by usage rather than by tag count. The raw number of
# unwrangled tags barely moves for a long time and is a discouraging number to
# show a volunteer; the share of actual taggings covered moves quickly.
class TagWrangling::Coverage
  CACHE_TTL = 15.minutes

  def initialize(type: nil)
    @type = type
  end

  def canonical_taggings
    counts[:canonical]
  end

  def total_taggings
    counts[:total]
  end

  def percentage
    return 100.0 if total_taggings.zero?
    ((canonical_taggings.to_f / total_taggings) * 100).round(1)
  end

  def remaining_tags
    counts[:remaining]
  end

  private

  def counts
    @counts ||= Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      scope = PostTag.joins(:tag)
      scope = scope.where(tags: { type: @type }) if @type
      {
        total: scope.count,
        canonical: scope.where(tags: { canonical: true }).count,
        remaining: tag_scope.awaiting_wrangling.count,
      }
    end
  end

  def tag_scope
    @type ? Tag.where(type: @type) : Tag.all
  end

  def cache_key
    "tag_wrangling/coverage/#{@type || 'all'}/#{Tag.maximum(:updated_at).to_i}"
  end
end
