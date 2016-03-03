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
    options_from_collection_for_select(zones, :name, :to_s, selected=default)
  end
end
