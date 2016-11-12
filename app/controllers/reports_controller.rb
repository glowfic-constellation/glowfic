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
    return false unless view
    view.ignored?
  end
  helper_method :ignored?

  def posts_for(day)
    posts = Post.where(tagged_at: day.beginning_of_day .. day.end_of_day).includes(:board, :user, :last_user)
    return unless posts.present?
    return posts.sort_by do |post|
      linked = linked_for(day, post)
      if linked.class == Post
        linked.edited_at
      else
        linked.created_at
      end
    end.reverse
  end
  helper_method :posts_for

  def linked_for(day, post, replies=nil)
    return post if post.created_at.to_date == day.to_date
    replies ||= post.replies.where(created_at: day.beginning_of_day .. day.end_of_day).order('created_at asc')
    return post if replies.empty?
    replies.first
  end
  helper_method :linked_for
end
