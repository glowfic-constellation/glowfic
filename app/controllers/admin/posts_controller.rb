# frozen_string_literal: true
class Admin::PostsController < Admin::AdminController
  before_action :require_split_permission, only: [:split, :do_split]
  before_action :require_regen_permission, only: [:regenerate_flat, :do_regenerate]

  def split
    @page_title = 'Split Post'
  end

  def do_split
    unless (@reply = Reply.find_by(id: params[:reply_id]))
      flash[:error] = "Reply could not be found."
      redirect_to split_posts_url and return
    end

    if params[:subject].blank?
      flash[:error] = "Subject must not be blank."
      redirect_to split_posts_url and return
    end
    preview_split and return if params[:button_preview].present?

    SplitPostJob.perform_later(params[:reply_id], params[:subject])
    flash[:success] = "Post will be split."
    redirect_to admin_url
  end

  def regenerate_flat
    @page_title = 'Regenerate Flat Posts'
  end

  def do_regenerate
    FlatPost.regenerate_all(params[:before], params[:force])
    flash[:success] = "Flat posts will be regenerated as needed."
    redirect_to admin_url
  end

  private

  def preview_split
    @page_title = 'Preview Split Post'
    render :preview_split
  end

  def require_split_permission
    return if current_user.has_permission?(:split_posts)
    flash[:error] = "You do not have permission to view that page."
    redirect_to admin_url
  end

  def require_regen_permission
    return if current_user.has_permission?(:regenerate_flat_posts)
    flash[:error] = "You do not have permission to view that page."
    redirect_to admin_url
  end
end
