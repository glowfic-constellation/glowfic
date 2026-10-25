# frozen_string_literal: true
# Deletes OAuth tokens and grants that can no longer be used: revoked ones, expired
# authorization codes, and expired access tokens without a refresh token. This is what
# Doorkeeper's doorkeeper:db:cleanup task does. Successful token requests enqueue it at most
# once a day, so it needs no scheduler.
class CleanOauthRecordsJob < ApplicationJob
  queue_as :default

  LOCK_KEY = 'oauth-records-cleanup-enqueued'

  def self.enqueue_daily
    return unless Rails.cache.write(LOCK_KEY, true, expires_in: 1.day, unless_exist: true)
    perform_later
  rescue StandardError => e
    # Don't hold the lock for a day if nothing was enqueued; cleanup is optional, so don't fail the token request.
    Rails.cache.delete(LOCK_KEY)
    Rails.error.report(e, handled: true)
  end

  def perform
    config = Doorkeeper.config
    Doorkeeper::StaleRecordsCleaner.new(config.access_token_model).clean_revoked
    expirable_tokens = config.access_token_model.where(refresh_token: nil)
    Doorkeeper::StaleRecordsCleaner.new(expirable_tokens).clean_expired(config.access_token_expires_in)
    # OpenID Connect nonces go with their grants (on_delete: :cascade).
    Doorkeeper::StaleRecordsCleaner.new(config.access_grant_model).clean_revoked
    Doorkeeper::StaleRecordsCleaner.new(config.access_grant_model).clean_expired(config.authorization_code_expires_in)
  end
end
