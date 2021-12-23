module IconHelper
  ICON = 'icon'.freeze
  NO_ICON = 'No Icon'.freeze
  NO_ICON_URL = 'icons/no-icon.png'.freeze
  CHAR_ICON = 'char-access-icon pointer'.freeze
  CHAR_ICON_FAKE = 'char-access-icon char-access-fake pointer'.freeze

  def icon_tag(icon, **args)
    return '' if icon.nil?
    icon_mem_tag(icon.url, icon.keyword, **args)
  end

  def icon_mem_tag(url, keyword, **args)
    return '' if url.nil?
    klass = ICON
    klass += ' pointer' if args.delete(:pointer)
    if (supplied_class = args.delete(:class))
      klass += ' ' + supplied_class
    end

    image_tag url, { alt: keyword, title: keyword, class: klass }.merge(**args)
  end

  def no_icon_tag(**args)
    icon_mem_tag(NO_ICON_URL, NO_ICON, **args)
  end

  def quick_switch_tag(image_url, short_text, hover_name, char_id)
    return tag.div short_text, class: CHAR_ICON_FAKE, title: hover_name, data: { character_id: char_id } if image_url.nil?
    image_tag image_url, class: CHAR_ICON, alt: hover_name, title: hover_name, data: { character_id: char_id }
  end

  def user_icon_tag(user)
    quick_switch_tag(user.avatar.try(:url), user.username[0..1], user.username, '')
  end

  def character_icon_tag(character)
    quick_switch_tag(character.default_icon.try(:url), character.name[0..1], character.selector_name, character.id)
  end

  def dropdown_icons(item, galleries=nil)
    icons = []
    selected_id = nil

    if item.character
      icons = if galleries.present?
        galleries.map(&:icons).flatten
      else
        item.character.icons
      end
      icons |= [item.character.default_icon] if item.character.default_icon
      icons |= [item.icon] if item.icon
      selected_id = item.icon_id
    elsif current_user.avatar
      icons = [current_user.avatar]
      selected_id = current_user.avatar_id
    end

    return '' unless icons.present?
    select_tag :icon_dropdown, options_for_select(icons.map {|i| [i.keyword, i.id]}, selected_id), prompt: "No Icon"
  end
end
