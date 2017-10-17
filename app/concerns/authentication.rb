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
      return unless logged_in?
      @current_user ||= User.find_by_id(session[:user_id])
      return @current_user if @current_user

      # logout - something has gone wrong, and the user id stored in session does not exist
      reset_session
      cookies.delete(:user_id, domain: '.glowfic.com')
      @current_user = nil
    end
    helper_method :current_user
  end
end
