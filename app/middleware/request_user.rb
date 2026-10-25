# frozen_string_literal: true

# Identifies the logged-in user from a Rack env, for middleware that runs
# before any controller.
#
# Readers who ticked "remember me" carry their credential in a permanent
# signed cookie rather than the session: the session cookie is configured
# with no expiry, so it dies with the browser, and
# `Authentication::Web#check_permanent_user` only promotes the cookie into
# the session once a controller runs. Middleware that checks the session
# alone therefore reads a genuinely logged-in reader as anonymous on their
# first request after a browser restart, and if it turns them away they
# never reach the controller that would have restored their session.
#
# The signature is verified rather than the cookie merely being checked for
# presence, so a scraper cannot pass as logged in by inventing a `user_id`
# cookie. Building the jar is a bare HMAC check, with no database work and no
# session written, and it only happens when the session has no user.
module RequestUser
  def self.id(env)
    session_user_id(env).presence || permanent_user_id(env).presence
  end

  def self.session_user_id(env)
    session = env['rack.session']
    session && session[:user_id]
  end

  def self.permanent_user_id(env)
    ActionDispatch::Request.new(env).cookie_jar.signed[:user_id]
  rescue StandardError
    # A malformed or unverifiable cookie is simply not a login; fall back to
    # the session verdict rather than letting a bad cookie raise a 500.
    nil
  end
  private_class_method :session_user_id, :permanent_user_id
end
