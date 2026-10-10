# frozen_string_literal: true

# Removes public caching from any response that sets a cookie.
class SharedCacheGuard
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    demote(headers) if shared?(headers) && identified?(headers)
    [status, headers, body]
  end

  private

  def header(headers, name)
    headers[name] || headers[name.split('-').map(&:capitalize).join('-')]
  end

  def shared?(headers)
    header(headers, 'cache-control').to_s.include?('public')
  end

  def identified?(headers)
    header(headers, 'set-cookie').present?
  end

  def demote(headers)
    headers.delete('Cache-Control')
    headers['cache-control'] = 'private, no-store'
    Rails.logger&.warn('[shared_cache_guard] withdrew public caching: response set a cookie')
  end
end
