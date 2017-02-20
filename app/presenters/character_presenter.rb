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
    char_json.merge!(aliases: character.aliases) if options[:include].include?(:aliases)
    return char_json unless options[:include].include?(:galleries)

    galleries = if character.galleries.present? && character.user.icon_picker_grouping?
      multi_gallery_json
    else
      single_gallery_json
    end
    char_json.merge(galleries: galleries)
  end

  def multi_gallery_json
    galleries = character.galleries.ordered.includes(:ordered_icons)
    galleries_json = galleries.map do |gallery|
      {
        name: gallery.name,
        icons: gallery.ordered_icons
      }
    end
  end

  def single_gallery_json
    if character.galleries.present?
      [{icons: character.icons}]
    elsif character.icon.present?
      [{icons: [character.icon]}]
    else
      []
    end
  end
end
