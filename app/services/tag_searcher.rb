# frozen_string_literal: true
class TagSearcher < Object
  def initialize
    @qs = Tag.ordered_by_type.select('tags.*')
  end

  def search(tag_name: nil, tag_type: nil, page: 1)
    validate_type!(tag_type) if tag_type.present?

    @qs = @qs.where('name ILIKE ?', "%#{tag_name}%") if tag_name.present?
    @qs = @qs.where(type: tag_type) if tag_type.present?
    @qs = @qs.includes(:user) if tag_type == 'Setting'
    @qs = @qs.where.not(type: 'GalleryGroup') unless tag_type == 'GalleryGroup'
    @qs = @qs.where.not(type: 'AccessCircle')
    @qs.with_character_counts.paginate(page: page)
  end

  def validate_type!(tag_type)
    return if (Tag::TYPES - ['AccessCircle']).include?(tag_type)
    raise InvalidTagType.new("Invalid filter")
  end
end
