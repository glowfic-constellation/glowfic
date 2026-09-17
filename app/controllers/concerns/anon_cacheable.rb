# frozen_string_literal: true

# Lets an action declare that its logged-out rendering may be held in a shared
# cache and served to other logged-out readers.
#
# Why this is worth doing: in the 24 hours to 2026-09-16 the site served
# 2,299,109 scraper page views across only 47,327 distinct URLs, and the
# thousand most-requested URLs accounted for 95.3% of all HTML traffic. The
# same handful of pages is fetched over and over. Held for five minutes, 84%
# of those origin requests disappear.
#
# The safety rule is the whole of this file: a response may be shared only if
# it contains nothing about the person who asked for it, and carries nothing
# that would attach an identity to the person who receives it. Three
# conditions enforce that, and every one of them must hold.
#
#   1. Nobody is logged in. A logged-in rendering names the reader, counts
#      their unread messages and marks their place in the thread.
#   2. The request is a plain GET. Anything else is an action, not a view.
#   3. The response sets no cookie. A `Set-Cookie` in a shared cache is handed
#      to the next reader, which would seat them in somebody else's session.
#
# Condition 3 is why `ApplicationController#store_location` is restricted to
# logged-in readers and why the layout omits `csrf_meta_tags` here: both write
# to the session, and writing to the session emits `Set-Cookie`. It is checked
# again at response time rather than assumed, because the cost of being wrong
# is serving one reader's session to another.
module AnonCacheable
  extend ActiveSupport::Concern

  # Shared caches hold the page for this long. Logged-in readers never reach
  # the cache at all, so the people writing and following a thread see their
  # own replies immediately; this is the delay a logged-out reader may see.
  SHARED_MAX_AGE = 5.minutes

  included do
    helper_method :anon_cacheable?
  end

  # True once an action has declared the response shareable AND the request
  # still satisfies the conditions. The layout asks this before rendering
  # anything that would write to the session.
  def anon_cacheable?
    @anon_cacheable.present? && shareable_request?
  end

  private

  def shareable_request?
    request.get? && !request.xhr? && !logged_in?
  end

  # Declares the logged-out rendering of this action shareable. Call it from
  # the action; it is a no-op for a logged-in reader, who keeps the private,
  # revalidated response the site has always sent.
  #
  # `max-age=0` keeps browsers revalidating, so a reader who refreshes gets a
  # current page; `s-maxage` is what the shared cache honours. `Vary: Cookie`
  # is the backstop: it tells any correct cache that a request carrying a
  # cookie is a different request, so even a CDN rule that failed to exclude
  # logged-in traffic could not hand them a shared copy.
  def cache_publicly
    return unless shareable_request?

    @anon_cacheable = true
    response.headers['Vary'] = [response.headers['Vary'], 'Cookie'].compact_blank.join(', ')
    # `s-maxage` is not one of the keys Rails' cache_control understands, so
    # it goes through :extras verbatim.
    response.cache_control.merge!(public: true, max_age: 0, extras: ["s-maxage=#{SHARED_MAX_AGE.to_i}"])
  end

  # The promise made above cannot be kept from inside the controller: the
  # session commits its cookie after every callback has run. `SharedCacheGuard`
  # enforces it from middleware, outside the session store.
end
