module WritableHelper
  def unread_warning
    return unless @replies.present?
    return if @replies.total_pages == page
    'You are not on the latest page of the thread ' + \
    tag.a('(View unread)', href: unread_path(@post), class: 'unread-warning') + ' ' + \
    tag.a('(New tab)', href: unread_path(@post), class: 'unread-warning', target: '_blank')
  end

  PRIVACY_MAP = {
    public: ['Public', 'world'],
    registered: ['Constellation Users', 'star'],
    access_list: ['Access List', 'group'],
    private: ['Private', 'lock'],
  }

  def post_or_reply_link(reply)
    return unless reply.id.present?
    post_or_reply_mem_link(id: reply.id, klass: reply.class)
  end

  def post_or_reply_mem_link(id: nil, klass: nil)
    return if id.nil?
    if klass == Reply
      reply_path(id, anchor: "reply-#{id}")
    else
      post_path(id)
    end
  end

  def has_edit_audits?(audits, written)
    return false unless written.id.present?
    if written.is_a?(Post)
      count = audits[:post]
    else
      count = audits.fetch(written.id, 0)
    end
    count > 1
  end
end
