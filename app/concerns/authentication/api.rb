# frozen_string_literal: true
module Authentication::Api
  extend ActiveSupport::Concern

  included do
    protected

    def logged_in?
      current_user.present?
    end

    def current_user
      @current_user ||= oauth_token_user || user_from_token
    end

    private

    def oauth_token_user
      token_value = request.headers['Authorization'].to_s.split(' ').last
      return unless token_value.present?
      OauthToken.find_by(token: token_value, invalidated_at: nil)&.user
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
      auth_header = request.headers['Authorization'].to_s.split(' ').last
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
