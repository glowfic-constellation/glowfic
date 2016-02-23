class CharacterPresenter
  attr_reader :character

  def initialize(character)
    @character = character
  end

  def as_json(*args, **kwargs)
    return {} unless character

    icons = if character.galleries.present?
      character.galleries.map(&:icons).flatten.uniq.sort_by{|i| i.keyword}.map(&:as_json) 
    elsif character.icon
      [character.icon.as_json]
    else
      []
    end

    { gallery: icons,
      default: character.icon.try(:as_json),
      name: character.name,
      screenname: character.screenname }
  end
end
