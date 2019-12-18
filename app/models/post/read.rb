module Post::Read
  extend ActiveSupport::Concern

  def first_unread_for(user)
    return @first_unread if @first_unread
    viewed_at = last_read(user) || board.last_read(user)
    return @first_unread = self unless viewed_at
    return unless has_replies?
    reply = replies.where('created_at > ?', viewed_at).ordered.first
    @first_unread ||= reply
  end

  def last_seen_reply_for(user)
    return @last_seen if @last_seen
    return unless has_replies? # unlike first_unread_for we don't care about the post
    viewed_at = last_read(user) || board.last_read(user)
    return unless viewed_at
    reply = replies.where('created_at <= ?', viewed_at).ordered.last
    @last_seen = reply
  end

  def read_time_for(viewing_replies)
    return self.edited_at if viewing_replies.empty?

    most_recent = viewing_replies.max_by(&:reply_order)
    most_recent_id = replies.select(:id).ordered.last.id
    return most_recent.created_at unless most_recent.id == most_recent_id # not on last page
    unless most_recent.updated_at > edited_at
      # testing for case where the post was changed in status more recently than the last reply
      audits_exist = audits.where('created_at > ?', most_recent.created_at).where(action: 'update')
      audits_exist = audits_exist.where("(audited_changes -> 'status' ->> 1)::integer = ?", Post.statuses[:complete])
      return edited_at if audits_exist
    end
    most_recent.updated_at
  end
end
