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
      return @current_user if @current_user && !@current_user.suspended?
      logout # nil means the user id stored in session does not exist, probably due to staging db reset
    end
    helper_method :current_user

    def logout
      reset_session
      cookies.delete(:user_id, cookie_delete_options)
      @current_user = nil
    end

    def cookie_delete_options
      return {domain: 'glowfic-staging.herokuapp.com'} if request.host.include?('staging')
      return {domain: '.glowfic.com'} if Rails.env.production?
      {}
    end
  end
end
