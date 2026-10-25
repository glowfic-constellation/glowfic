# frozen_string_literal: true
# OpenID Connect on top of the OAuth2 provider: lets other sites offer "Log in with Glowfic".
site_url = "#{Rails.env.production? ? 'https' : 'http'}://#{ENV.fetch('DOMAIN_NAME', 'localhost:3000')}"

Doorkeeper::OpenidConnect.configure do
  issuer site_url

  signing_key -> { Authentication.oidc_signing_key }
  subject_types_supported [:public]

  resource_owner_from_access_token { |access_token| Authentication.oauth_user(access_token.resource_owner_id) }
  subject { |user, _application| user.id }

  # Glowfic does not record when a user logged in, so there is no auth_time
  # to report, and prompt=login and max_age answer login_required.
  auth_time_from_resource_owner { |_user| nil }
  reauthenticate_resource_owner { |_user, _return_to| nil }
  select_account_for_resource_owner { |_user, _return_to| nil }

  # Email addresses are never shared.
  claims do
    claim(:preferred_username, scope: :profile, response: [:id_token, :user_info]) { |user, _scopes| user.username }
    claim(:name, scope: :profile, response: [:id_token, :user_info]) { |user, _scopes| user.username }
    claim :profile, scope: :profile, response: [:id_token, :user_info] do |user, _scopes|
      Rails.application.routes.url_helpers.user_url(user, host: site_url)
    end
  end
end
