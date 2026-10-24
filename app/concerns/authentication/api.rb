# frozen_string_literal: true
module Authentication::Api
  extend ActiveSupport::Concern

  included do
    protected

    def logged_in?
      current_user.present?
    end

    def current_user
      @current_user ||= jwt_request? ? user_from_token : oauth_user
    end

    private

    # Our JWTs always have three dot-separated segments, and Doorkeeper's opaque tokens
    # (the default hex generator) never contain a dot, so this cleanly tells them apart.
    # Don't configure a JWT or dotted access_token_generator without revisiting it.
    def jwt_request?
      authorization_value.to_s.count('.') == 2
    end

    def authorization_value
      request.headers['Authorization'].to_s.split(' ').last
    end

    def oauth_user
      return unless authorization_value.present?
      user = Authentication.oauth_user(doorkeeper_token.resource_owner_id) if doorkeeper_token&.acceptable?([:api])
      return user if user
      render_invalid_oauth_token unless performed?
      nil
    end

    def render_invalid_oauth_token
      error = { message: "Authorization token is not valid." }
      response.headers['WWW-Authenticate'] = 'Bearer error="invalid_token"'
      render json: { errors: [error] }, status: :unauthorized
    end

    def user_from_token
      user_id = decoded_api_token[:user_id]
      return unless user_id
      User.find_by(id: user_id)
    end

    def decoded_api_token
      @decoded_token ||= decode_api_token
    end

    # handle edge case errors more reasonably
    def decode_api_token
      auth_header = authorization_value
      return {} unless auth_header.present?
      decode_value(auth_header)
    end

    def decode_value(value)
      body = Authentication.read_api_token(value)
      ActiveSupport::HashWithIndifferentAccess.new(body)
    rescue JWT::ExpiredSignature
      error = { message: "Authorization token has expired." }
      session[:api_token] = nil
      render json: { errors: [error] }, status: :unauthorized
      {}
    rescue JWT::DecodeError
      error = { message: "Authorization token is not valid." }
      session[:api_token] = nil
      render json: { errors: [error] }, status: :unprocessable_entity
      {}
    end
  end
end
