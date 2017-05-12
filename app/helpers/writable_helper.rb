module WritableHelper
  def unread_warning
    return unless @replies.present?
    return if @replies.total_pages == page
    'Post has unread replies ' + \
    content_tag(:a, '(View)', href: unread_path(@post, warn_id: @last_seen_id.to_i), class: 'unread-warning') + ' ' + \
    content_tag(:a, '(New Tab)', href: unread_path(@post), class: 'unread-warning', target: '_blank')
  end

  def unread_path(post, **kwargs)
    post_path(post, page: 'unread', anchor: 'unread', **kwargs)
  end
end
