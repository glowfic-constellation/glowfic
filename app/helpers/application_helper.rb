module ApplicationHelper
  ICON = 'icon'.freeze
  NO_ICON = 'No Icon'.freeze
  NO_ICON_URL = '/images/no-icon.png'.freeze
  TIME_FORMAT = '%b %d, %Y %l:%M %p'.freeze
  CHAR_ICON = 'char-access-icon pointer'.freeze

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

    image_tag url, {alt: keyword, title: keyword, class: klass}.merge(**args)
  end

  def no_icon_tag(**args)
    icon_mem_tag(NO_ICON_URL, NO_ICON, **args)
  end

  def quick_switch_tag(image_url, short_text, hover_name, char_id)
    if image_url.nil?
      return content_tag :div, short_text, class: CHAR_ICON, title: hover_name, data: { character_id: char_id }
    end
    image_tag image_url, class: CHAR_ICON, alt: hover_name, title: hover_name, data: { character_id: char_id }
  end

  def user_icon_tag(user)
    quick_switch_tag(user.avatar.try(:url), user.username[0..1], user.username, '')
  end

  def character_icon_tag(character)
    quick_switch_tag(character.default_icon.try(:url), character.name[0..1], character.selector_name, character.id)
  end

  def swap_icon_url
    return '/images/swap.png' unless current_user
    return '/images/swap.png' unless current_user.layout.to_s.start_with?('starry')
    '/images/swapgray.png'
  end

  def pretty_time(time, format=nil)
    return unless time
    time.strftime(format || current_user.try(:time_display) || TIME_FORMAT)
  end

  def fun_name(user)
    return user.username unless user.moiety
    content_tag :span, user.username, style: 'font-weight: bold; color: #' + user.moiety
  end

  def color_block(user)
    return unless user.moiety
    content_tag :span, '█', style: 'cursor: default; color: #' + user.moiety, title: user.moiety_name
  end

  def unread_img
    return '/images/note_go.png' unless current_user
    return '/images/note_go.png' unless current_user.layout
    return '/images/note_go.png' unless current_user.layout.include?('dark')
    '/images/bullet_go.png'
  end

  def lastlink_img
    return '/images/note_go_strong.png' unless current_user
    return '/images/note_go_strong.png' unless current_user.layout
    return '/images/note_go_strong.png' unless current_user.layout.include?('dark')
    '/images/bullet_go_strong.png'
  end

  def path_for(obj, path)
    send (path + '_path') % obj.class.to_s.downcase, obj
  end

  def per_page_options(default=nil)
    default ||= per_page
    default = nil if default.to_i > 100

    options = [10, 25, 50, 100]
    options << default unless default.nil? || default.zero? || options.include?(default)
    options = Hash[*(options * 2).sort]
    options_for_select(options, default)
  end

  def timezone_options(default=nil)
    default ||= 'Eastern Time (US & Canada)'
    zones = ActiveSupport::TimeZone.all
    options_from_collection_for_select(zones, :name, :to_s, default)
  end

  def layout_options(default=nil)
    layouts = {
      'Default': nil,
      'Dark': 'dark'.freeze,
      'Iconless': 'iconless'.freeze,
      'Starry': 'starry'.freeze,
      'Starry Dark' => 'starrydark'.freeze,
      'Starry Light' => 'starrylight'.freeze,
      'Monochrome': 'monochrome'.freeze,
      'Milky River' => 'river'.freeze,
    }
    options_for_select(layouts, default)
  end

  def time_display_options(default=nil)
    time_thing = Time.new(2016, 12, 25, 21, 34, 56) # Example time: "2016-12-25 21:34:56" (for unambiguous display purposes)
    time_display_list = [
      "%b %d, %Y %l:%M %p", "%b %d, %Y %H:%M", "%b %d, %Y %l:%M:%S %p", "%b %d, %Y %H:%M:%S",
      "%d %b %Y %l:%M %p", "%d %b %Y %H:%M", "%d %b %Y %l:%M:%S %p", "%d %b %Y %H:%M:%S",
      "%m-%d-%Y %l:%M %p", "%m-%d-%Y %H:%M", "%m-%d-%Y %l:%M:%S %p", "%m-%d-%Y %H:%M:%S",
      "%d-%m-%Y %l:%M %p", "%d-%m-%Y %H:%M", "%d-%m-%Y %l:%M:%S %p", "%d-%m-%Y %H:%M:%S",
      "%Y-%m-%d %l:%M %p", "%Y-%m-%d %H:%M", "%Y-%m-%d %l:%M:%S %p", "%Y-%m-%d %H:%M:%S"
    ]
    time_displays = Hash[time_display_list.map { |v| [time_thing.strftime(v), v] }]
    options_for_select(time_displays, default)
  end

  def sanitize_post_description(desc)
    Sanitize.fragment(desc, elements: ['a'], attributes: {'a' => ['href']})
  end

  def sanitize_written_content(content)
    content = (content.include?("<p>".freeze) || content[/<br ?\/?>/]) ? content : content.gsub("\n".freeze, "<br/>".freeze)
    Sanitize.fragment(content, Glowfic::POST_CONTENT_SANITIZER)
  end

  def generate_short(msg)
    short_msg = Sanitize.fragment(msg) # strip all tags, replacing appropriately with spaces
    return short_msg if short_msg.length <= 75
    short_msg[0...73] + '…' # make the absolute max length 75 characters
  end

  def post_privacy_settings
    { 'Public'              => Post::PRIVACY_PUBLIC,
      'Constellation Users' => Post::PRIVACY_REGISTERED,
      'Access List'         => Post::PRIVACY_LIST,
      'Private'             => Post::PRIVACY_PRIVATE }
  end

  def unread_post?(post, unread_ids)
    return false unless post
    return false unless unread_ids
    unread_ids.include?(post.id)
  end

  def opened_post?(post, opened_ids)
    return false unless post
    return false unless opened_ids
    opened_ids.include?(post.id)
  end

  def message_sender(message)
    return message.sender_name if message.site_message?
    link_to(message.sender_name, user_path(message.sender))
  end
end
