# frozen_string_literal: true
# OAuth2 provider: lets third-party applications act on a user's behalf through the API.
Doorkeeper.configure do
  orm :active_record

  base_controller 'ApplicationController'

  resource_owner_authenticator do
    next current_user if logged_in?
    # Only a GET can be replayed after login; a POST/DELETE from an expired consent form has lost its params.
    session[:previous_url] = request.fullpath if request.get?
    flash.now[:error] = "You must be logged in to authorize an application."
    @page_title = 'Sign In'
    render 'sessions/new', status: :unauthorized
    nil
  end

  enable_application_owner confirmation: true

  grant_flows %w[authorization_code]
  use_refresh_token
  force_pkce
  # "plain" sends the verifier itself as the challenge, which protects nothing.
  pkce_code_challenge_methods %w[S256]

  # Store only digests: a database leak must not leak usable credentials.
  # This means an application secret is shown once, when it is generated.
  hash_token_secrets
  hash_application_secrets

  access_token_methods :from_bearer_authorization

  # A user deleted or suspended since approving an application gets no new tokens.
  before_successful_strategy_response do |request|
    token = request.access_token
    next if Authentication.oauth_user(token.resource_owner_id)
    token.revoke
    raise Doorkeeper::Errors::InvalidGrant, Doorkeeper::OAuth::ErrorResponse.new(name: :invalid_grant)
  end

  after_successful_strategy_response do |_request, _response|
    CleanOauthRecordsJob.enqueue_daily
  end

  default_scopes :api
  optional_scopes :openid, :profile

  # Plain http is only acceptable for a client running on the user's machine.
  force_ssl_in_redirect_uri { |uri| ['localhost', '127.0.0.1', '[::1]'].exclude?(uri.host) }
end

# The consent and authorized-applications pages use the site layout, like every other page.
Rails.application.config.to_prepare do
  Doorkeeper::AuthorizationsController.layout 'application'
  Doorkeeper::AuthorizedApplicationsController.layout 'application'
end
