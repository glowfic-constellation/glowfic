# frozen_string_literal: true
class ReportsController < ApplicationController
  def index
  end

  REPORT_TYPES = ['daily', 'monthly']

  def show
    @report_type = REPORT_TYPES.detect {|x| x == params[:id] }
    unless @report_type
      flash[:error] = "Could not identify the type of report."
      redirect_to reports_path
    end

    @page_title = params[:id].capitalize + " Report"
    @hide_quicklinks = true
    if params[:day].present?
      @day = begin
         params[:day].in_time_zone(Time.zone).to_date
       rescue NoMethodError # invalid time stamps processed with .in_time_zone return nil
         Time.zone.now.to_date
       end
    else
      @day = Time.zone.now.to_date
    end

    if logged_in?
      @opened_posts = PostView.where(user_id: current_user.id).select([:post_id, :read_at, :ignored])
      @board_views = BoardView.where(user_id: current_user.id).select([:board_id, :ignored])
      @opened_ids = @opened_posts.map(&:post_id)

      DailyReport.mark_read(current_user, @day) if !current_user.ignore_unread_daily_report? && @day.to_date < Time.zone.now.to_date
    end
  end

  private

  def has_unread?(post)
    return false unless @opened_posts.present?
    view = @opened_posts.detect { |v| v.post_id == post.id }
    return false unless view
    return false if view.ignored?
    return false if view.read_at.nil? # totally unread, not partially
    view.read_at < post.tagged_at
  end
  helper_method :has_unread?

  def never_read?(post)
    return false unless logged_in?
    return true unless @opened_posts.present?
    view = @opened_posts.detect { |v| v.post_id == post.id }
    return true unless view
    return false if view.ignored?
    view.read_at.nil?
  end
  helper_method :never_read?

  def ignored?(post)
    return false unless @opened_posts.present?
    view = @opened_posts.detect { |v| v.post_id == post.id }
    board_view = @board_views.detect { |v| v.board_id == post.board_id }
    return false unless view || board_view
    view.try(:ignored?) || board_view.try(:ignored?)
  end
  helper_method :ignored?

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
        'LOWER(max(boards.name)), tagged_at desc'
      else
        'first_updated_at desc'
    end
  end
  helper_method :sort
end
