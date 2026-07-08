# frozen_string_literal: true
module ReportsHelper
  def has_unread?(post)
    return false unless @opened_posts.present?
    view = @opened_posts.detect { |v| v.post_id == post.id }
    return false unless view
    return false if view.ignored?
    return false if view.read_at.nil? # totally unread, not partially
    return true if view.read_at < post.tagged_at
    view.last_read_reply_order.present? && view.last_read_reply_order < post.reply_count
  end

  def never_read?(post)
    return false unless logged_in?
    return true unless @opened_posts.present?
    view = @opened_posts.detect { |v| v.post_id == post.id }
    return true unless view
    return false if view.ignored?
    view.read_at.nil?
  end

  def ignored?(post)
    return false unless @opened_posts.present?
    view = @opened_posts.detect { |v| v.post_id == post.id }
    board_view = @board_views.detect { |v| v.board_id == post.board_id }
    return false unless view || board_view
    view.try(:ignored?) || board_view.try(:ignored?)
  end
end
