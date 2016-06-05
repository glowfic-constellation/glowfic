class ReportsController < ApplicationController
  around_filter :set_fixed_timezone

  def index
  end

  def show
    unless ['daily', 'monthly'].include?(params[:id])
      flash[:error] = "Could not identify the type of report."
      redirect_to reports_path
    end
  end

  private

  def set_fixed_timezone(&block)
    Time.use_zone("Alaska", &block)
  end

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
    replies ||= post.replies.where(created_at: day.beginning_of_day .. day.end_of_day).order('created_at asc')
    return post if replies.empty? || post.created_at.to_date == day.to_date
    replies.first
  end
  helper_method :linked_for
end
