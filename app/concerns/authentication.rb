module Authentication
  extend ActiveSupport::Concern

  included do
    protected

    def check_permanent_user
      return if logged_in?
      session[:user_id] = cookies.signed[:user_id] if cookies.signed[:user_id].present?
    end

    def logged_in?
      session[:user_id].present?
    end
    helper_method :logged_in?

    def current_user
      @current_user ||= User.find_by_id(session[:user_id]) if logged_in?
    end
    helper_method :current_user
  end
end
