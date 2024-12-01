# frozen_string_literal: true
class Admin::PostsController < Admin::AdminController
  before_action :require_regen_permission, only: [:regenerate_flat, :do_regenerate]

  def regenerate_flat
    @page_title = 'Regenerate Flat Posts'
  end

  def do_regenerate
    FlatPost.regenerate_all(params[:before], params[:force])
    flash[:success] = "Flat posts will be regenerated as needed."
    redirect_to admin_url
  end

  private

  def require_regen_permission
    return if current_user.has_permission?(:regenerate_flat_posts)
    flash[:error] = "You do not have permission to view that page."
    redirect_to admin_url
  end
end
