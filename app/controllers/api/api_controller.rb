class Api::ApiController < ActionController::Base
  include Authentication

  protect_from_forgery with: :exception
  before_filter :check_permanent_user
  around_filter :set_timezone

  protected

  def login_required
    return if logged_in?
    error = {message: "You must be logged in to view that page."}
    render json: {errors: [error]}, status: :unauthorized and return
  end

  def set_timezone
    Time.use_zone("UTC") { yield }
  end

  def access_denied
    error = {message: "You do not have permission to perform this action."}
    render json: {errors: [error]}, status: :forbidden
  end
end
