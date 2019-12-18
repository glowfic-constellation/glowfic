module Post::Read
  extend ActiveSupport::Concern

  included do
    def first_unread_for(user)
      return self unless (viewed_at = viewed_at(user))
      return unless has_replies?
      replies.where('created_at > ?', viewed_at).ordered.first
    end

    def last_seen_reply_for(user)
      return unless has_replies? # unlike first_unread_for we don't care about the post
      return unless (viewed_at = viewed_at(user))
      replies.where('created_at <= ?', viewed_at).ordered.last
    end

    def read_time_for(viewing_replies)
      return self.edited_at if viewing_replies.empty?

      most_recent = viewing_replies.max_by(&:reply_order)
      select_read_timestamp(most_recent)
    end

    private

    def viewed_at(user)
      last_read(user) || board.last_read(user)
    end

    def select_read_timestamp(most_recent)
      if most_recent.reply_order == replies.ordered.last.reply_order # whether we're on the last page
        return self.edited_at if more_recent_status?(most_recent) # if the post was changed in status more recently than the last reply
        most_recent.updated_at
      else
        most_recent.created_at
      end
    end

    def more_recent_status?(most_recent)
      return false if most_recent.updated_at > self.edited_at
      audits_exist = audits.where('created_at > ?', most_recent.created_at).where(action: 'update')
      audits_exist.where("(audited_changes -> 'status' ->> 1)::integer = ?", Post.statuses[:complete]).exists?
    end
  end
end
