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
  end
end
