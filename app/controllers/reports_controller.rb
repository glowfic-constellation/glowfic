class ReportsController < ApplicationController
  def index
  end

  def show
    unless ['daily', 'monthly'].include?(params[:id])
      flash[:error] = "Could not identify the type of report."
      redirect_to reports_path
    end

    if logged_in?
      @opened_posts = PostView.where(user_id: current_user.id).select([:post_id, :read_at, :ignored])
      @board_views = BoardView.where(user_id: current_user.id).select([:board_id, :ignored])
      @opened_ids = @opened_posts.map(&:post_id)
    end
  end

  private

  def has_unread?(post)
    return false unless @opened_posts
    view = @opened_posts.detect { |v| v.post_id == post.id }
    return false unless view
    return false if view.ignored?
    view.read_at < post.tagged_at
  end
  helper_method :has_unread?

  def ignored?(post)
    return false unless @opened_posts
    view = @opened_posts.detect { |v| v.post_id == post.id }
    board_view = @board_views.detect { |v| v.board_id == post.board_id }
    return false unless view || board_view
    view.try(:ignored?) || board_view.try(:ignored?)
  end
  helper_method :ignored?

  def posts_for(day)

    Post.where(tagged_at: day.beginning_of_day .. day.end_of_day).includes(:board, :user, :last_user).order(sort)
  end
  helper_method :posts_for

  def linked_for(day, post, replies=nil)
    return post if post.created_at.to_date == day.to_date
    replies ||= post.replies.where(created_at: day.beginning_of_day .. day.end_of_day).order('created_at asc')
    return post if replies.empty?
    replies.first
  end
  helper_method :linked_for

  def sort
    @sort ||= case params[:sort]
      when 'subject'
        'LOWER(subject)'
      when 'continuity'
        'LOWER(boards.name), tagged_at desc'
      else
        'tagged_at desc'
    end
  end
end
