module WritableHelper
  def unread_warning
    return @unread_warning unless @unread_warning.nil?
    # Get unread_reply separately from @post.first_unread_for because that caches (and sometimes does "halfway down the page you just loaded" when we want 'first unread after the whole page has loaded')
    viewed_at = @post.last_read(current_user) || @post.board.last_read(current_user)
    unread_reply = if viewed_at
      @post.replies.where('created_at > ?', viewed_at).order('id asc').first
    else
      @post
    end
    return (@unread_warning = false) unless unread_reply
    @unread_warning = content_tag :a, 'Post has unread replies', href: post_or_reply_link(unread_reply), class: 'unread-warning'
  end
end
