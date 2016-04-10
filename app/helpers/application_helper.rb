module ApplicationHelper
  def icon_tag(icon, **args)
    return '' if icon.nil?

    klass = 'icon'
    klass += ' pointer' if args.delete(:pointer)
    image_tag icon.url, {alt: icon.keyword, title: icon.keyword, class: klass}.merge(**args)
  end

  def no_icon_tag(**args)
    klass = 'icon'
    klass += ' pointer' if args.delete(:pointer)
    image_tag "/images/no-icon.png", {class: klass, alt:'No Icon', title: 'No Icon'}.merge(**args)
  end

  def pretty_time(time)
    return unless time
    time.strftime("%b %d, %Y %l:%M %p")
  end

  def fun_name(user)
    return user.username unless user.moiety
    content_tag :span, user.username, style: 'font-weight: bold; color: #' + user.moiety
  end

  def color_block(user)
    return unless user.moiety
    content_tag :span, '⬤', style: 'color: #' + user.moiety
  end

  def path_for(obj, path)
    send (path + '_path') % obj.class.to_s.downcase, obj
  end

  def per_page_options(default=nil)
    options = [1,10,25,50,100,250,500]
    options = Hash[*(options * 2).sort].merge({'All' => 'all'})
    default ||= per_page
    default = 'all' if default == -1
    options_for_select(options, default)
  end

  def timezone_options(default=nil)
    default ||= 'Eastern Time (US & Canada)'
    zones = ActiveSupport::TimeZone.all()
    options_from_collection_for_select(zones, :name, :to_s, default)
  end

  def post_or_reply_link(reply)
    return unless reply.id.present?
    if reply.is_a?(Reply)
      reply_path(reply, anchor: "reply-#{reply.id}")
    else
      post_path(reply)
    end
  end
end
