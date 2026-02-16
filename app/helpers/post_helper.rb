# frozen_string_literal: true
module PostHelper
  def author_links(post, linked: true, colored: false)
    total = post.authors.size
    authors = post.authors.reject(&:deleted?).sort_by { |a| a.username.downcase }
    num_deleted = total - authors.size
    deleted = 'deleted user'.pluralize(num_deleted)
    return "(#{deleted})" if authors.empty?

    if total < 4
      links = authors.map { |author| linked ? user_link(author, colored: colored) : author.username }
      joined_links = safe_join(links, ', ')
      return joined_links if num_deleted.zero?
      return safe_join([joined_links, "#{num_deleted} #{deleted}"], ' and ')
    end

    # filter post.user from post.authors to avoid n+1 query over post.user
    first_author = authors.find { |x| x.id == post.user_id } || authors.first

    first_link = linked ? user_link(first_author, colored: colored) : first_author.username
    hovertext = safe_join((authors - [first_author]).map(&:username), ', ')
    others = linked ? link_to("#{total - 1} others", stats_post_path(post), title: hovertext) : "#{total - 1} others"
    safe_join([first_link, others], ' and ')
  end

  def allowed_boards(obj, user)
    authored_ids = BoardAuthor.where(user: user).select(:board_id)
    Board.where(id: obj.board_id).or(Board.where(authors_locked: false)).or(Board.where(id: authored_ids)).ordered
  end

  def unread_path(post, **kwargs)
    post_path(post, page: 'unread', anchor: 'unread', **kwargs)
  end

  def anchored_continuity_path(post)
    return continuity_path(post.board_id) unless post.section_id.present?
    continuity_path(post.board_id, anchor: "section-#{post.section_id}")
  end

  def post_privacy_settings
    {
      'Public'              => :public,
      'Constellation Users' => :registered,
      'Full Users'          => :full_accounts,
      'Access List'         => :access_list,
      'Private'             => :private,
    }
  end

  PRIVACY_MAP = {
    # name, icon, icon_darkmode
    public: ['Public', 'world', 'world'],
    registered: ['Constellation Users', 'stars_constellation', 'stars_constellation_darkmode'],
    full_accounts: ['Full Users', 'star_tricolor', 'star_tricolor'],
    access_list: ['Access List', 'group', 'group'],
    private: ['Private', 'lock', 'lock'],
  }

  def privacy_state(privacy, dark_layout: false, auto_layout: false)
    privacy = privacy.to_sym
    privacy_icon(privacy, dark_layout: dark_layout, auto_layout: auto_layout, alt: false) + ' ' + PRIVACY_MAP[privacy][0]
  end

  def privacy_icon(privacy, dark_layout: false, auto_layout: false, alt: true)
    name, icon, icon_dark = PRIVACY_MAP[privacy]
    text = alt ? name : ''
    if auto_layout && icon != icon_dark
      return auto_image_tag("icons/#{icon}.png", "icons/#{icon_dark}.png", class: 'vmid', title: name, alt: text)
    end
    img = dark_layout ? icon_dark : icon
    image_tag("icons/#{img}.png", class: 'vmid', title: name, alt: text)
  end

  def menu_img
    return 'icons/menu.png' unless current_user.try(:layout).to_s.start_with?('starry') || current_user.try(:layout).to_s.start_with?('auto_starry')
    'icons/menugray.png'
  end

  def shortened_desc(desc, id)
    return sanitize_simple_link_text(desc) if desc.length <= 255
    sanitize_simple_link_text(desc[0...255]) +
      tag.span('... ', id: "dots-#{id}") +
      tag.span(sanitize_simple_link_text(desc[255..-1]), class: 'hidden', id: "desc-#{id}") +
      tag.a('more &raquo;'.html_safe, href: '#', id: "expanddesc-#{id}", class: 'expanddesc')
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
end
