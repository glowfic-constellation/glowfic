module ApplicationHelper
  def icon_tag(icon, **args)
    return '' if icon.nil?

    klass = 'icon'
    klass += ' pointer' if args.delete(:pointer)
    image_tag icon.url, {alt: icon.keyword, title: icon.keyword, class: klass}.merge(**args)
  end

  def post_time(time)
    time ||= Time.now
    time_string = time.hour.to_s + time.strftime(":%M %p") + '<br>' + time.strftime("%b %d %Y")
    time_string.html_safe
  end

  def path_for(obj, path)
    send (path + '_path') % obj.class.to_s.downcase, obj
  end

  def per_page_options(default=nil)
    options = [1,10,25,50,100,250,500]
    options = Hash[*(options * 2).sort].merge({'All' => -1})
    default ||= per_page
    options_for_select(options, default)
  end
end
