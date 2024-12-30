# frozen_string_literal: true
module Authentication::Web
  extend ActiveSupport::Concern

  included do
    protected

    def check_permanent_user
      # transition users from old authentication to devise-based authentication
      return if logged_in?
      return unless cookies.signed[:user_id].present?

      unless (user = User.find_by(id: cookies.signed[:user_id]))
        logout
        return
      end

      sign_in(:user, user)
    end

    # alias devise methods for backwards compatibility
    # (current_user set by devise)
    def logged_in?
      user_signed_in?
    end
    helper_method :logged_in?

    def logout
      reset_session
      session.delete(:api_token)
      sign_out(:user)
      @current_user = nil
    end

    # set user API token for use in API requests
    def set_user_token
      unless current_user
        session[:api_token] = nil
        return
      end

      expiration = session[:api_token].try(:[], "expires").to_i
      session[:api_token] = nil if Time.zone.now.to_i > expiration
      session[:api_token] ||= {
        "value"   => Authentication.generate_api_token(current_user),
        "expires" => Authentication::EXPIRY.from_now.to_i,
      }
    end
  end
end
