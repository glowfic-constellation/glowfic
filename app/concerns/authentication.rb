module Authentication
  extend ActiveSupport::Concern

  included do
    protected

    before_action :set_session_from_cookie

    def set_session_from_cookie
      return if session[:user_id].present?
      session[:user_id] = cookies.signed[:user_id]
    end

    def logged_in?
      !!current_user
    end
    helper_method :logged_in?

    def current_user
      return @current_user if @current_user
      return nil unless session[:user_id].present?

      user = User.find_by_id(session[:user_id])
      logout unless user.present? # the user id stored in session does not exist, probably due to staging db reset
      @current_user = user
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
