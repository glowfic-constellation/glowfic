# frozen_string_literal: true

# Marks a logged-out GET response as shareable by a cache. It must set no cookie.
module AnonCacheable
  extend ActiveSupport::Concern

  SHARED_MAX_AGE = 5.minutes

  included do
    helper_method :anon_cacheable?
  end

  def anon_cacheable?
    @anon_cacheable.present? && shareable_request?
  end

  private

  def shareable_request?
    request.get? && !request.xhr? && !logged_in?
  end

  # No-op for a logged-in reader.
  def cache_publicly
    return unless shareable_request?

    @anon_cacheable = true
    response.headers['Vary'] = [response.headers['Vary'], 'Cookie'].compact_blank.join(', ')
    # Rails' cache_control has no s-maxage key.
    response.cache_control.merge!(public: true, max_age: 0, extras: ["s-maxage=#{SHARED_MAX_AGE.to_i}"])
  end
end
