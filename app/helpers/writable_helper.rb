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
end
