# frozen_string_literal: true
module IconHelper
  ICON = 'icon'
  NO_ICON = 'No Icon'
  NO_ICON_URL = 'icons/no-icon.png'
  CHAR_ICON = 'char-access-icon pointer'
  CHAR_ICON_FAKE = 'char-access-icon char-access-fake pointer'

  # Reverse image search engines used to help identify a facecast from an uploaded icon.
  # {url} is replaced with the (encoded) image url. Google Lens/TinEye lean towards real
  # people; Yandex/SauceNAO also cover anime, art and other fictional facecasts.
  REVERSE_IMAGE_SEARCH_ENGINES = [
    ['Google Lens', 'https://lens.google.com/uploadbyurl?url={url}'],
    ['Yandex', 'https://yandex.com/images/search?rpt=imageview&url={url}'],
    ['TinEye', 'https://tineye.com/search?url={url}'],
    ['SauceNAO', 'https://saucenao.com/search.php?url={url}'],
  ].freeze

  def icon_tag(icon, **args)
    return '' if icon.nil?
    icon_mem_tag(icon.url, icon.keyword, **args)
  end

  def icon_mem_tag(url, keyword, lookup_asset: false, **args)
    return '' if url.nil?
    klass = ICON
    klass += ' pointer' if args.delete(:pointer)
    if (supplied_class = args.delete(:class))
      klass += ' ' + supplied_class
    end

    args = { alt: keyword, title: keyword, class: klass }.merge(args)

    if lookup_asset
      image_tag url, **args
    else
      tag.img(src: url, **args)
    end
  end

  def no_icon_tag(**args)
    icon_mem_tag(NO_ICON_URL, NO_ICON, lookup_asset: true, **args)
  end

  # Renders reverse image search links for an (optionally not-yet-uploaded) icon url. The
  # data-search-template attributes let reverse_image_search.js refill the links after a
  # fresh upload, so the same markup works for existing icons and ones uploaded in-page.
  def reverse_image_search_links(url, id: nil)
    classes = ['reverse-image-search']
    classes << 'hidden' if url.blank?

    label = tag.span('Identify facecast:', class: 'reverse-image-search-label')
    links = REVERSE_IMAGE_SEARCH_ENGINES.map do |name, template|
      href = url.present? ? template.sub('{url}', CGI.escape(url.to_s)) : '#'
      link_to(name, href, class: 'reverse-image-search-link', target: '_blank',
        rel: 'noopener noreferrer', data: { search_template: template },)
    end

    tag.div(safe_join([label, *links], ' '), id: id, class: classes.join(' '), data: { image_url: url.presence })
  end

  def quick_switch_tag(image_url, short_text, hover_name, char_id)
    return tag.div short_text, class: CHAR_ICON_FAKE, title: hover_name, data: { character_id: char_id } if image_url.nil?
    tag.img(src: image_url, class: CHAR_ICON, alt: hover_name, title: hover_name, data: { character_id: char_id })
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
    select_tag :icon_dropdown, options_for_select(icons.map { |i| [i.keyword, i.id] }, selected_id), prompt: "No Icon"
  end
end
