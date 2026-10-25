# frozen_string_literal: true
# Requests that an OAuth client sends from its own server, not through the user's browser.
# They carry no session cookie and usually come from a hosting provider, so the defences
# against anonymous scrapers in Rack::Attack and AnonLoadShed would refuse them.
module OauthRequest
  # Doorkeeper's token, revoke, introspect and token info endpoints, and OpenID Connect's
  # userinfo and keys. /oauth/authorize and /oauth/authorized_applications are browser pages.
  BACKCHANNEL_PATHS = %w[
    /oauth/token
    /oauth/revoke
    /oauth/introspect
    /oauth/token/info
    /oauth/userinfo
    /oauth/discovery/keys
  ].freeze

  # The OpenID Connect discovery documents (openid-configuration, oauth-authorization-server, webfinger).
  def self.backchannel?(path)
    path.start_with?('/.well-known/') || BACKCHANNEL_PATHS.include?(path)
  end

  # An API call with a token. Without a valid token it gets nothing: the API answers 401 or 422
  # before any action runs, so a scraper gains nothing by adding a made-up one.
  def self.bearer_api?(path, authorization)
    path.start_with?('/api/') && authorization.to_s.match?(/\ABearer /i)
  end

  def self.client?(path, authorization)
    backchannel?(path) || bearer_api?(path, authorization)
  end
end
