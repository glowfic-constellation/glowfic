class CharacterPresenter
  attr_reader :character

  def initialize(character)
    @character = character
  end

  def as_json(options={})
    return {} unless character
    char_json = character.as_json_without_presenter(only: [:id, :name, :screenname])
    return char_json unless options[:include].present?

    char_json.merge!(default: character.icon.try(:as_json)) if options[:include].include?(:default)
    return char_json unless options[:include].include?(:galleries)

    galleries = if character.galleries.present? && character.user.icon_picker_grouping?
      multi_gallery_json
    else
      single_gallery_json
    end
    char_json.merge(galleries: galleries)
  end

  def multi_gallery_json
    galleries = character.galleries.ordered.includes(:icons)
    galleries_json = galleries.map do |gallery|
      {
        name: gallery.name,
        icons: gallery.icons.order('LOWER(keyword)')
      }
    end
  end

  def single_gallery_json
    if character.galleries.present?
      [{icons: character.galleries.map(&:icons).flatten.uniq.sort_by {|i| i.keyword}}]
    elsif character.icon.present?
      [{icons: [character.icon]}]
    else
      []
    end
  end
end
