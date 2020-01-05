class DailyReport < Report
  attr_reader :day

  def initialize(day)
    @day = day
  end

  def posts(sort='')
    range = day.beginning_of_day .. day.end_of_day
    created_no_replies = Post.where(last_reply_id: nil, created_at: range)
    by_replies = Post.where(id: Reply.where(created_at: range).distinct.select(:post_id))
    all_posts = created_no_replies.or(by_replies)
    all_posts
      .select(ActiveRecord::Base.sanitize_sql_array([
        "posts.*,
        case
        when (posts.created_at between ? AND ?)
          then posts.created_at
          else coalesce(min(replies_today.created_at), posts.created_at)
          end as first_updated_at",
        range.begin,
        range.end,
      ]))
      .joins("LEFT JOIN replies AS replies_today ON replies_today.post_id = posts.id")
      .where("replies_today.created_at IS NULL OR (replies_today.created_at between ? AND ?)", range.begin, range.end)
      .group("posts.id")
      .order(sort)
  end

  def self.unread_date_for(user)
    # ignores reports in progress
    return nil unless user
    return nil if user.ignore_unread_daily_report?
    last_read = last_read(user)
    return 1.day.ago.to_date unless last_read
    return nil unless last_read.to_date < 1.day.ago.to_date
    (last_read + 1.day).to_date
  end
end
