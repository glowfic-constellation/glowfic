# frozen_string_literal: true
module ApplicationHelper
  TIME_FORMAT = '%b %d, %Y %l:%M %p'

  # Injected skins are scoped under this descendant prefix to lift their
  # specificity above the app's own theming rules (which lean on :nth-child / #id
  # selectors). ":root" matches the <html> element, so the prefix never changes
  # which elements a selector matches. The safety overrides below share the same
  # prefix, so they keep beating the skin on ties via source order.
  SKIN_SCOPE = ':root:root'

  # Appended after every injected skin. Skins have `!important` stripped by the
  # sanitizer, so these always win: critical chrome (content warnings, flashes,
  # the ToS gate) stays visible and un-overlaid no matter what a skin tries.
  #
  # The property list is the set of ways CSS can hide, shrink-to-nothing, move
  # off-screen, or de-interact an element, each pinned to its "no-op" value:
  #   * hide:    display, visibility, opacity
  #   * collapse: height, max-height, overflow
  #   * move/transform: position, transform AND the independent transform
  #     properties (scale/rotate/translate, which bypass `transform: none`)
  #   * clip away: clip, clip-path
  #   * obscure: filter (e.g. opacity()/blur())
  #   * disable: pointer-events
  SKIN_SAFETY_OVERRIDES = <<~CSS
    #{SKIN_SCOPE} .flash, #{SKIN_SCOPE} .flash.error, #{SKIN_SCOPE} .flash-margin, #{SKIN_SCOPE} #tos {
      display: block !important;
      visibility: visible !important;
      opacity: 1 !important;
      position: static !important;
      height: auto !important;
      max-height: none !important;
      overflow: visible !important;
      transform: none !important;
      scale: none !important;
      rotate: none !important;
      translate: none !important;
      filter: none !important;
      clip: auto !important;
      clip-path: none !important;
      pointer-events: auto !important;
    }
  CSS

  # Builds the <style> tag a viewer should get for a skin, or nil. css_for picks
  # the tier: the owner and approved skins get raw CSS, everyone else gets the
  # stripped safe version. Selectors are scoped under SKIN_SCOPE so the skin
  # reliably out-ranks the app's defaults without needing !important. The gsub
  # neutralises any "</..." so even raw CSS cannot break out of the <style>
  # element into markup/script.
  def skin_style_tag(skin, viewer: current_user)
    return if skin.nil?

    css = skin.css_for(viewer)
    return if css.blank?

    scoped = Glowfic::CssSanitizer.scope(css, SKIN_SCOPE)
    payload = "#{scoped}\n#{SKIN_SAFETY_OVERRIDES}".gsub('</', '<\/')
    tag.style(payload.html_safe, type: 'text/css')
  end

  def loading_tag(**args)
    klass = 'vmid loading-icon'
    klass += ' ' + args[:class] if args[:class]
    image_tag 'icons/loading.gif', title: 'Loading...', class: klass, alt: '...', id: args[:id]
  end

  def swap_icon_url
    return 'icons/swap.png' unless current_user.try(:layout)
    return 'icons/swap.png' unless current_user.layout_darkmode? || current_user.layout.start_with?('starry')
    'icons/swapgray.png'
  end

  def pretty_time(time, format: nil)
    return unless time
    content_tag(:time, datetime: time.utc.iso8601, title: time.utc.strftime("%Y-%m-%d %H:%M %Z")) do
      time.in_time_zone.strftime(format || current_user.try(:time_display) || TIME_FORMAT)
    end
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
    return 'icons/note_go.png' unless current_user&.layout_darkmode?
    'icons/bullet_go.png'
  end

  def lastlink_img
    return 'icons/note_go_strong.png' unless current_user&.layout_darkmode?
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
      Dark: 'dark',
      Iconless: 'iconless',
      Starry: 'starry',
      'Starry Dark' => 'starrydark',
      'Starry Light' => 'starrylight',
      Monochrome: 'monochrome',
      'Milky River' => 'river',
      Pesterchum: 'pesterchum',
      'Pesterchum Memo' => 'pesterchummemo',
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
      "%Y-%m-%d %l:%M %p", "%Y-%m-%d %H:%M", "%Y-%m-%d %l:%M:%S %p", "%Y-%m-%d %H:%M:%S",
    ]
    time_displays = time_display_list.index_by { |v| time_thing.strftime(v) }
    options_for_select(time_displays, default)
  end

  def sanitize_simple_link_text(text)
    Glowfic::Sanitizers.description(text)
  end

  def breakable_text(text)
    return text if text.nil?
    h(text).gsub('_', '_<wbr>').html_safe
  end

  def index_privacy_settings
    {
      'Public'              => :public,
      'Constellation Users' => :registered,
      'Private'             => :private,
    }
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
