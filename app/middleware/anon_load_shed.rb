# frozen_string_literal: true

# Returns a 503 to non-logged-in users whose request has already been waiting
# in Puma's queue longer than `WAIT_THRESHOLD_SECONDS` by the time it gets a
# worker. Frees the worker to serve a logged-in request from the queue
# instead.
#
# This is a load-shedding layer that complements the steady-state rate limits
# in `config/initializers/rack_attack.rb`. Under normal load the queue wait
# is sub-100ms and this middleware passes everything through unchanged; it
# only triggers when the system is genuinely saturated (large queues, slow
# requests, dyno restart re-saturation). When that happens, anonymous
# traffic gets a fast 503 + Retry-After instead of being held in queue and
# eventually rack-timeout-aborted; logged-in traffic continues normally.
#
# `WAIT_THRESHOLD_SECONDS` is deliberately well above normal latency and
# well below `RACK_TIMEOUT_WAIT_TIMEOUT`, so anonymous users still get fast
# service in steady state, and only shed when the queue is actually deep
# enough that rack-timeout would have failed them in another few seconds
# anyway.
class AnonLoadShed
  WAIT_THRESHOLD_SECONDS = 5.0

  # Requests that look like the distributed scrape are shed an order of
  # magnitude sooner, so that when the queue does back up it is the scraper
  # that loses its thread slot rather than whichever reader happened to arrive
  # at the same moment.
  #
  # In the seven days to 2026-09-09 the scrape was 9.7M of the 12.5M HTML
  # navigations and 469 of the 594 dyno-hours spent serving them, while 65,595
  # genuine page loads (2.4%) were shed as collateral. Both classes were
  # competing on the same 5s threshold, so the shedder was splitting the
  # damage between them instead of aiming it.
  #
  # This is still a threshold and not a block: below it, scraper-shaped
  # traffic is served exactly as before. It only bites once the queue is deep
  # enough that somebody is going to be shed regardless, and it decides who.
  SCRAPER_WAIT_THRESHOLD_SECONDS = 0.5

  def initialize(app)
    @app = app
  end

  # The checks are ordered cheapest-first, because each one is a pass-through:
  # ordering changes only the work done on the way to a verdict, never the
  # verdict itself.
  #
  # The queue-wait check leads because it is both the cheapest and by far the
  # most common answer — in steady state nothing is saturated, so this costs
  # one env lookup and returns. The shape check comes next at two header string
  # comparisons, and only runs on requests already waiting long enough to be
  # worth classifying. Identifying the user comes last because it means
  # building a cookie jar to verify a signature, which is only worth doing on
  # the rare request we are otherwise about to shed.
  def call(env)
    waited = wait_seconds(env)
    return @app.call(env) if waited.nil? || waited < SCRAPER_WAIT_THRESHOLD_SECONDS
    return @app.call(env) if waited < WAIT_THRESHOLD_SECONDS && !scraper_shaped?(env)
    return @app.call(env) if login_request?(env)
    return @app.call(env) if logged_in?(env)
    [
      503,
      { 'Content-Type' => 'text/plain', 'Retry-After' => '30' },
      ["Server busy, please try again shortly.\n"],
    ]
  end

  private

  # Chrome announces `application/signed-exchange;v=b3;q=0.7` on HTML
  # navigations. Measured across glowfic traffic by Chrome major version, every
  # genuine release from 120 to 141 sits at 95-100%; the scrape's rotating
  # forged UA strings sit at 0.0-0.3%, alongside self-declared crawlers. Over
  # the seven days to 2026-09-09 the pair of conditions split HTML navigations
  # 9,745,482 scraper-shaped against 2,744,787 real.
  #
  # Both halves of the test matter. Requiring the Chrome claim is what makes it
  # safe: Firefox and Safari never send the token either, so testing on Accept
  # alone would classify every one of their users as a scraper. Requiring the
  # missing token is what makes it useful, since the UA strings themselves are
  # forged and are shared with real readers.
  #
  # Restricting to `text/html` keeps this to navigations. Subresource requests
  # are not classified here — they carry a different Accept, and a page's
  # images should not be judged separately from the page.
  #
  # This is a header-level heuristic, which is the most forgeable tier there
  # is; it informs a threshold rather than a block precisely because it can be
  # defeated the moment anyone cares to.
  def scraper_shaped?(env)
    accept = env['HTTP_ACCEPT']
    return false unless accept&.start_with?('text/html')
    return false if accept.include?('signed-exchange')
    env['HTTP_USER_AGENT'].to_s.include?('Chrome/')
  end

  def logged_in?(env)
    session_user_id(env).present? || permanent_user_id(env).present?
  end

  def session_user_id(env)
    session = env['rack.session']
    session && session[:user_id]
  end

  # Readers who ticked "remember me" carry their credential in a permanent
  # signed cookie rather than the session: the session cookie is configured
  # with no expiry, so it dies with the browser, and
  # `Authentication::Web#check_permanent_user` only promotes the cookie into
  # the session once a controller runs — which is after this middleware.
  #
  # Checking the session alone therefore reads a genuinely logged-in reader as
  # anonymous on their first request after a browser restart, and they cannot
  # retry their way out of it: a shed response never reaches the controller
  # that would have restored their session, so every refresh sheds again for
  # as long as the queue stays deep. Only /login, exempted above, breaks the
  # loop.
  #
  # The signature is verified rather than the cookie merely being checked for
  # presence, so a scraper cannot opt out of shedding by inventing a `user_id`
  # cookie. Building the jar is a bare HMAC check — no database work, and no
  # session is written, so a shed request still costs what it did before.
  def permanent_user_id(env)
    ActionDispatch::Request.new(env).cookie_jar.signed[:user_id]
  rescue StandardError
    # A malformed or unverifiable cookie is simply not a login; fall back to
    # the session verdict rather than letting a bad cookie raise a 500.
    nil
  end

  # A logged-out user has no way to become prioritized except by logging in, so
  # genuine login traffic must never be shed: let /login (both the form and the
  # POST) wait in the long queue instead. Spamming this path to dodge the shed
  # is bounded by the rack-attack throttle on POST /login, and our threat model
  # is scraping rather than login floods.
  def login_request?(env)
    env['PATH_INFO'] == '/login'
  end

  # rack-timeout stores its RequestDetails (including .wait, the seconds the
  # request spent in the dyno's queue before reaching a worker) under
  # Rack::Timeout::ENV_INFO_KEY. The gem is production-only, so resolve the
  # constant defensively: where it isn't loaded there is no queue-wait info
  # and we never shed.
  def wait_seconds(env)
    return nil unless defined?(Rack::Timeout::ENV_INFO_KEY)
    env[Rack::Timeout::ENV_INFO_KEY]&.wait
  end
end
