class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  protected

  def current_user
    @current_user ||= User.find_by_id(session[:user_id]) if logged_in?
  end
  helper_method :current_user

  def logged_in?
    session[:user_id].present?
  end
  helper_method :logged_in?
end
