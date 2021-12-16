module ApplicationHelper
  TIME_FORMAT = '%b %d, %Y %l:%M %p'.freeze

  def loading_tag(**args)
    klass = 'vmid loading-icon'
    klass += ' ' + args[:class] if args[:class]
    image_tag 'icons/loading.gif', title: 'Loading...', class: klass, alt: '...', id: args[:id]
  end

  def swap_icon_url
    return 'icons/swap.png' unless current_user.try(:layout)
    return 'icons/swap.png' unless current_user.layout.start_with?('starry') || current_user.layout == 'dark'
    'icons/swapgray.png'
  end

  def pretty_time(time, format: nil)
    return unless time
    time.strftime(format || current_user.try(:time_display) || TIME_FORMAT)
  end

  def fun_name(user)
    return '(deleted user)'.html_safe if user.deleted?
    return user.username unless user.moiety
    tag.span user.username, style: "font-weight: bold; color: ##{user.moiety}"
  end

  def color_block(user)
    return unless user.moiety
    tag.span '█', style: "cursor: default; color: ##{user.moiety}", title: user.moiety_name
  end

  def unread_img
    return 'icons/note_go.png' unless current_user
    return 'icons/note_go.png' unless current_user.layout
    return 'icons/note_go.png' unless current_user.layout.include?('dark')
    'icons/bullet_go.png'
  end

  def lastlink_img
    return 'icons/note_go_strong.png' unless current_user
    return 'icons/note_go_strong.png' unless current_user.layout
    return 'icons/note_go_strong.png' unless current_user.layout.include?('dark')
    'icons/bullet_go_strong.png'
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
    # Layout identifiers (values in this hash) are expected to not include spaces,
    # so they are suitable as HTML classes for the TinyMCE editor
    layouts = {
      Default: nil,
      Dark: 'dark'.freeze,
      Iconless: 'iconless'.freeze,
      Starry: 'starry'.freeze,
      'Starry Dark' => 'starrydark'.freeze,
      'Starry Light' => 'starrylight'.freeze,
      Monochrome: 'monochrome'.freeze,
      'Milky River' => 'river'.freeze,
    }
    options_for_select(layouts, default)
  end

  def time_display_options(default=nil)
    time_thing = Time.new(2016, 12, 25, 21, 34, 56).utc # Example time: "2016-12-25 21:34:56" (for unambiguous display purposes)
    time_display_list = [
      "%b %d, %Y %l:%M %p", "%b %d, %Y %H:%M", "%b %d, %Y %l:%M:%S %p", "%b %d, %Y %H:%M:%S",
      "%d %b %Y %l:%M %p", "%d %b %Y %H:%M", "%d %b %Y %l:%M:%S %p", "%d %b %Y %H:%M:%S",
      "%m-%d-%Y %l:%M %p", "%m-%d-%Y %H:%M", "%m-%d-%Y %l:%M:%S %p", "%m-%d-%Y %H:%M:%S",
      "%d-%m-%Y %l:%M %p", "%d-%m-%Y %H:%M", "%d-%m-%Y %l:%M:%S %p", "%d-%m-%Y %H:%M:%S",
      "%Y-%m-%d %l:%M %p", "%Y-%m-%d %H:%M", "%Y-%m-%d %l:%M:%S %p", "%Y-%m-%d %H:%M:%S"
    ]
    time_displays = time_display_list.index_by { |v| time_thing.strftime(v) }
    options_for_select(time_displays, default)
  end

  def sanitize_simple_link_text(text)
    Glowfic::Sanitizers.description(text)
  end

  # modified version of split_paragraphs that doesn't mangle large breaks
  # https://apidock.com/rails/v4.2.7/ActionView/Helpers/TextHelper/split_paragraphs
  def split_paragraphs_largebreak(text)
    return [] if text.blank?
    text.to_str.gsub(/\r\n?/, "\n").split("\n\n").map! do |t|
      t.gsub!(/(^\n|[^\n]\n)(?=[^\n])/, '\1<br />') || t
    end
  end

  # modified version of simple_format that doesn't mangle large breaks
  # https://apidock.com/rails/ActionView/Helpers/TextHelper/simple_format
  def simple_format_largebreak(text, options={})
    wrapper_tag = options.fetch(:wrapper_tag, :p)
    text = sanitize(text) if options.fetch(:sanitize, true)
    paragraphs = split_paragraphs_largebreak(text)

    if paragraphs.empty?
      content_tag(wrapper_tag, nil)
    else
      paragraphs.map! { |paragraph|
        if paragraph.empty?
          content_tag(wrapper_tag, '&nbsp;'.html_safe)
        else
          content_tag(wrapper_tag, raw(paragraph))
        end
      }.join("\n\n").html_safe
    end
  end

  P_TAG = /<p( [^>]*)?>/
  BR_TAG = /<br *\/?>/
  BLOCKQUOTE_QUICK_SEARCH = '<blockquote'.freeze
  BLOCKQUOTE_TAG = /<blockquote( |>)/
  LINEBREAK = /\r?\n/
  BR = '<br>'.freeze

  # specific blockquote handling is due to simple_format wanting to wrap a blockquote in a paragraph
  def sanitize_written_content(content)
    unless content[P_TAG] || content[BR_TAG]
      content = if content[BLOCKQUOTE_QUICK_SEARCH] && content[BLOCKQUOTE_TAG]
        content.gsub(LINEBREAK, BR)
      else
        simple_format_largebreak(content, sanitize: false)
      end
    end

    Glowfic::Sanitizers.written(content)
  end

  def breakable_text(text)
    return text if text.nil?
    h(text).gsub('_', '_<wbr>').html_safe
  end

  def post_privacy_settings
    { 'Public'              => :public,
      'Constellation Users' => :registered,
      'Access List'         => :access_list,
      'Private'             => :private }
  end

  def index_privacy_settings
    { 'Public'              => :public,
      'Constellation Users' => :registered,
      'Private'             => :private }
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
    link_to(message.sender_name, message.sender)
  end

  def user_link(user, colored: false)
    username = colored ? fun_name(user) : user.username
    user_mem_link(user.id, username, user.deleted?)
  end

  def user_mem_link(user_id, username, deleted)
    return '(deleted user)'.html_safe if deleted
    link_to username, user_path(user_id)
  end
end
