class Admin::AdminController < ApplicationController
  before_action :login_required
  before_action :require_permission, only: :index

  def index
    @page_title = 'Admin Tools'
  end

  private

  def require_permission
    return if current_user.mod? || current_user.admin?
    flash[:error] = "You do not have permission to view that page."
    redirect_to root_url
  end
end
