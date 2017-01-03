module ApplicationHelper
  ICON = 'icon'.freeze
  NO_ICON = 'No Icon'.freeze
  NO_ICON_URL = '/images/no-icon.png'.freeze
  TIME_FORMAT = '%b %d, %Y %l:%M %p'.freeze


  def icon_tag(icon, **args)
    return '' if icon.nil?
    icon_mem_tag(icon.url, icon.keyword, **args)
  end

  def icon_mem_tag(url, keyword, **args)
    return '' if url.nil?
    klass = ICON
    klass += ' pointer' if args.delete(:pointer)
    if supplied_class = args.delete(:class)
      klass += ' ' + supplied_class
    end

    image_tag url, {alt: keyword, title: keyword, class: klass}.merge(**args)
  end

  def no_icon_tag(**args)
    icon_mem_tag(NO_ICON_URL, NO_ICON, **args)
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

  def path_for(obj, path)
    send (path + '_path') % obj.class.to_s.downcase, obj
  end

  def per_page_options(default=nil)
    default ||= per_page
    options = [10,25,50,100,250,500,1000]
    options << default unless default.nil? || default.zero? || options.include?(default)
    all = 'all'.freeze
    options = Hash[*(options * 2).sort].merge({'All' => all})
    default = all if default == -1
    options_for_select(options, default)
  end

  def timezone_options(default=nil)
    default ||= 'Eastern Time (US & Canada)'
    zones = ActiveSupport::TimeZone.all()
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

  def post_or_reply_link(reply)
    return unless reply.id.present?
    if reply.is_a?(Reply)
      reply_path(reply, anchor: "reply-#{reply.id}")
    else
      post_path(reply)
    end
  end

  def sanitize_post_description(desc)
    Sanitize.fragment(desc, elements: ['a'], attributes: {'a' => ['href']})
  end

  def sanitize_post_content(content)
    content = (content.include?("<p>".freeze) || content[/<br ?\/?>/]) ? content : content.gsub("\n".freeze,"<br/>".freeze)
    Sanitize.fragment(content, Glowfic::POST_CONTENT_SANITIZER)
  end

  def post_privacy_settings
    { 'Public'              => Post::PRIVACY_PUBLIC,
      'Constellation Users' => Post::PRIVACY_REGISTERED,
      'Access List'         => Post::PRIVACY_LIST,
      'Private'             => Post::PRIVACY_PRIVATE }
  end
end
