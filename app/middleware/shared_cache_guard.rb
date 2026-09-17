# frozen_string_literal: true

# Withdraws shared caching from any response that turned out to identify
# somebody.
#
# `AnonCacheable` lets an action declare its logged-out rendering shareable.
# The action cannot keep that promise on its own: the session is committed by
# `ActionDispatch::Session::CookieStore`, which runs after every controller
# callback has finished. A controller `after_action` asking whether a cookie
# is going out is therefore always told no, however late it is registered.
#
# So the check runs here instead, and this middleware is inserted *before* the
# session store (see config/application.rb) so that on the way back out the
# session has already written its `Set-Cookie` and this can see it.
#
# The rule it enforces: a response carrying a cookie describes one particular
# person, and a shared cache would hand that response — and that cookie — to
# whoever asks next. Caching such a response would seat a stranger in
# somebody else's session, so the caching is removed rather than the cookie.
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

  # Rack 3 specifies lowercase header names, but this sits among middleware
  # that predates that, so read both spellings rather than trust either.
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
