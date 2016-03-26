class CharacterPresenter
  attr_reader :character, :current_user

  def initialize(character, current_user)
    @character = character
    @current_user = current_user
  end

  def as_json(*args, **kwargs)
    return {} unless character
    
    galleries = if character.galleries.present?
      if current_user.icon_picker_grouping
        galls = character.galleries.includes(:icons).order('name asc')
        temp = []
        galls.each do |gallery|
          temp << {name: gallery.name, icons: gallery.icons.uniq.sort_by {|i| i.keyword}}
        end
        temp
      else
        icons = character.galleries.map(&:icons).flatten.uniq.sort_by {|i| i.keyword}
        [{icons: icons}]
      end
    elsif character.icon
      [{icons: character.icon.as_json}]
    else
      []
    end

    { galleries: galleries,
      default: character.icon.try(:as_json),
      name: character.name,
      screenname: character.screenname }
  end
end
