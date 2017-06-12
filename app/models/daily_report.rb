class DailyReport < Report
  attr_reader :day

  def initialize(day)
    @day = day
  end

  def posts(sort='')
    created_no_replies = Post.where(last_reply_id: nil, created_at: day.beginning_of_day .. day.end_of_day).pluck(:id)
    edited_no_replies = Post.where(last_reply_id: nil, tagged_at: day.beginning_of_day .. day.end_of_day).pluck(:id)
    by_replies = Reply.where(created_at: day.beginning_of_day .. day.end_of_day).pluck(:post_id)
    all_post_ids = created_no_replies + edited_no_replies + by_replies
    Post.where(id: all_post_ids.uniq)
      .select('posts.*, boards.name as board_name')
      .joins(:board)
      .order(sort)
  end

  def self.unread_date_for(user)
    # ignores reports in progress
    return nil unless user
    last_read = last_read(user)
    return 1.day.ago.to_date.to_s unless last_read
    return nil unless last_read.to_date < 1.day.ago.to_date
    (last_read + 1.day).to_date.to_s
  end
end
