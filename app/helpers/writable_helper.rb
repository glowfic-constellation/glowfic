module WritableHelper
  def unread_warning
    return unless @replies.present?
    return if @replies.total_pages == page
    'You are not on the latest page of the thread ' + \
    content_tag(:a, '(View unread)', href: unread_path(@post), class: 'unread-warning') + ' ' + \
    content_tag(:a, '(New tab)', href: unread_path(@post), class: 'unread-warning', target: '_blank')
  end

  def unread_path(post, **kwargs)
    post_path(post, page: 'unread', anchor: 'unread', **kwargs)
  end

  def anchored_board_path(post)
    return board_path(post.board_id) unless post.section_id.present?
    board_path(post.board_id, anchor: "section-#{post.section_id}")
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
    select_tag :icon_dropdown, options_for_select(icons.map{|i| [i.keyword, i.id]}, selected_id), prompt: "No Icon"
  end

  PRIVACY_MAP = {
    Concealable::PUBLIC      => ['Public', 'world'],
    Concealable::REGISTERED  => ['Constellation Users', 'star'],
    Concealable::ACCESS_LIST => ['Access List', 'group'],
    Concealable::PRIVATE     => ['Private', 'lock'],
  }

  def privacy_state(privacy)
    privacy_icon(privacy) + ' ' + PRIVACY_MAP[privacy][0]
  end

  def privacy_icon(privacy)
    name = PRIVACY_MAP[privacy][0]
    img = PRIVACY_MAP[privacy][1]
    image_tag("icons/#{img}.png", class: 'vmid', title: name)
  end

  STATUS_MAP = {
    Post::STATUS_ACTIVE    => ['In Progress', 'book_open'],
    Post::STATUS_COMPLETE  => ['Complete', 'book'],
    Post::STATUS_HIATUS    => ['On Hiatus', 'hourglass'],
    Post::STATUS_ABANDONED => ['Abandoned', 'book_grey'],
  }

  def status_state(status, only_icon: false, only_text: false, short_title: false)
    raise ArgumentError("Invalid status: #{status}") unless STATUS_MAP.key?(status)
    status_info = STATUS_MAP[status]
    name = status_info[0]
    img = status_info[1]
    return name if only_text
    icon = image_tag("icons/#{img}.png", class: 'vmid', title: "#{'Thread' unless short_title} #{name}")
    return icon if only_icon
    [icon, name].safe_join(' ')
  end

  def menu_img
    return 'icons/menu.png' unless current_user.try(:layout).to_s.start_with?('starry')
    'icons/menugray.png'
  end

  def shortened_desc(desc, id)
    return sanitize_simple_link_text(desc) if desc.length <= 255
    sanitize_simple_link_text(desc[0...255]) +
      content_tag(:span, '... ', id: "dots-#{id}") +
      content_tag(:span, sanitize_simple_link_text(desc[255..-1]), class: 'hidden', id: "desc-#{id}") +
      content_tag(:a, 'more &raquo;'.html_safe, href: '#', id: "expanddesc-#{id}", class: 'expanddesc')
  end
end
