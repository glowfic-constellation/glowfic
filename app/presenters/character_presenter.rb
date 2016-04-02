class CharacterPresenter
  attr_reader :character

  def initialize(character)
    @character = character
  end

  def as_json(*args, **kwargs)
    return {} unless character

    galleries = if character.galleries.present? && character.user.icon_picker_grouping?
      multi_gallery_json
    else
      single_gallery_json
    end

    { galleries: galleries,
      default: character.icon.try(:as_json),
      name: character.name,
      screenname: character.screenname }
  end

  def multi_gallery_json
    galleries = character.galleries.includes(:icons).order('name asc')
    galleries_json = galleries.map do |gallery|
      {
        name: gallery.name,
        icons: gallery.icons.sort_by { |i| i.keyword }
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
