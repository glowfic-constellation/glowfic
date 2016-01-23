class CharacterPresenter
  attr_reader :character

  def initialize(character)
    @character = character
  end

  def as_json(*args, **kwargs)
    Rails.logger.info(character)
    return {} unless character
    icons = character.gallery ? character.gallery.icons.order("keyword ASC").map(&:as_json) : []
    { gallery: icons,
      default: character.icon.try(:as_json),
      name: character.name,
      screenname: character.screenname }
  end
end
