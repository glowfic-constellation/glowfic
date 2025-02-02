# frozen_string_literal: true
module Authentication::Web
  extend ActiveSupport::Concern

  included do
    protected

    include Devise::Controllers::Rememberable

    def migrate_old_authentication
      # transition users from old authentication to devise-based authentication
      return if logged_in?
      return unless cookies.signed[:user_id].present?

      # if the old cookie's corresponding user isn't found, log them out
      unless (user = User.find_by(id: cookies.signed[:user_id]))
        logout
        return
      end

      # transition the old authentication to the new Devise session
      # (can't do the rememberable cookie without upgrading their password hash: requires authenticatable_salt to be set!)
      logout
      sign_in(:user, user)
      if user.authenticatable_salt.present?
        remember_me(user)
        flash[:notice] = "Your session has been restored!"
      else
        flash[:notice] =
          "Our password security has been upgraded. " \
          "Your session has been temporarily restored, but please log out and back in to save a new 'Remember Me' token!"
      end
    end

    # alias devise methods for backwards compatibility
    # (current_user set by devise)
    def logged_in?
      user_signed_in?
    end
    helper_method :logged_in?

    def logout
      reset_session
      cookies.delete(:user_id, cookie_options) # delete old-style authentication token
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

    def cookie_options
      return { domain: 'glowfic-staging.herokuapp.com' } if request.host.include?('staging')
      return { domain: '.glowfic.com', tld_length: 2 } if Rails.env.production?
      {}
    end
  end
end
