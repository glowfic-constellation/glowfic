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
class AnonLoadShed
  # Logged-out requests with no scraper signal. ANON_SHED_WAIT_SECONDS overrides it.
  WAIT_THRESHOLD_SECONDS = ENV.fetch('ANON_SHED_WAIT_SECONDS', '2.0').to_f.clamp(0.5, 15.0)

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
  # ANON_SHED_SCRAPER_WAIT_SECONDS overrides it.
  SCRAPER_WAIT_THRESHOLD_SECONDS = ENV.fetch('ANON_SHED_SCRAPER_WAIT_SECONDS', '0.3').to_f.clamp(0.1, 2.0)

  # ANON_SHED_SEC_FETCH=off leaves only the signed-exchange check.
  SEC_FETCH_TEST = ENV.fetch('ANON_SHED_SEC_FETCH', 'on') != 'off'

  # ANON_SHED_NO_COOKIE=off turns off the no_cookie signal.
  NO_COOKIE_TEST = ENV.fetch('ANON_SHED_NO_COOKIE', 'on') != 'off'

  # Chrome sends Sec-CH-UA from version 89.
  CLIENT_HINTS_SINCE = 90

  def initialize(app)
    @app = app
  end

  # The checks are ordered cheapest-first, because each one is a pass-through:
  # ordering changes only the work done on the way to a verdict, never the
  # verdict itself.
  #
  # The queue-wait check leads because it is both the cheapest and by far the
  # most common answer — in steady state nothing is saturated, so this costs
  # one env lookup and returns. The shape check comes next at a handful of
  # header string comparisons, and only runs on requests already waiting long
  # enough to be worth classifying. Identifying the user comes last because it means
  # building a cookie jar to verify a signature, which is only worth doing on
  # the rare request we are otherwise about to shed.
  def call(env)
    waited = wait_seconds(env)
    return @app.call(env) if waited.nil? || waited < SCRAPER_WAIT_THRESHOLD_SECONDS
    return @app.call(env) if waited < WAIT_THRESHOLD_SECONDS && !self.class.scraper_signal(env)
    return @app.call(env) if login_request?(env)
    return @app.call(env) if safe_ip?(env)
    return @app.call(env) if logged_in?(env)
    record_shed(env)
    [
      503,
      { 'Content-Type' => 'text/plain', 'Retry-After' => '30' },
      ["Server busy, please try again shortly.\n"],
    ]
  end

  # Why a request looks like the scrape, or nil. A class method so ClientFingerprint
  # can record it on every request.
  def self.scraper_signal(env)
    accept = env['HTTP_ACCEPT'].to_s
    (accept.start_with?('text/html') && chrome_signal(env, accept)) || cookie_signal(env)
  end

  # A GET with no cookie at all, outside the API, unless it followed a link from
  # another site. Readers send the session cookie from their second page on.
  def self.cookie_signal(env)
    return nil unless NO_COOKIE_TEST
    return nil unless env['REQUEST_METHOD'] == 'GET'
    return nil if env['PATH_INFO'].to_s.start_with?('/api/')
    return nil if env['HTTP_COOKIE'].present?
    return nil if env['HTTP_SEC_FETCH_SITE'] == 'cross-site'
    'no_cookie'
  end

  def self.chrome_signal(env, accept)
    user_agent = env['HTTP_USER_AGENT'].to_s
    major = user_agent[/Chrome\/(\d+)/, 1]
    return nil unless major
    return 'no_sxg' unless accept.include?('signed-exchange')
    return nil unless SEC_FETCH_TEST
    return 'no_sec_fetch' if env['HTTP_SEC_FETCH_MODE'].blank?
    return nil if user_agent.include?('; wv)') || major.to_i < CLIENT_HINTS_SINCE
    # GREASE changes the fake brand and the order of the list, but not the Chromium entry.
    client_hint = env['HTTP_SEC_CH_UA']
    return 'no_ch_ua' if client_hint.blank?
    return 'ch_ua_mismatch' unless client_hint.include?(%("Chromium";v="#{major}"))
    nil
  end

  # The agent drops metrics recorded inside an ignored transaction, so sheds are
  # counted here and flushed from a thread outside any transaction.
  FLUSH_SECONDS = 60

  @shed_counts = Hash.new(0)
  @shed_lock = Mutex.new

  def self.count_shed(name)
    @shed_lock.synchronize do
      start_flusher unless @flusher_pid == Process.pid
      @shed_counts[name] += 1
    end
  end

  def self.flush_shed_counts
    counts = @shed_lock.synchronize do
      taken = @shed_counts
      @shed_counts = Hash.new(0)
      taken
    end
    counts.each { |name, count| NewRelic::Agent.increment_metric(name, count) }
  end

  # A thread does not survive Puma's fork, so each worker starts its own.
  def self.start_flusher
    @flusher_pid = Process.pid
    @shed_counts = Hash.new(0)
    Thread.new do
      loop do
        sleep FLUSH_SECONDS
        flush_shed_counts
      rescue StandardError => e
        Rails.logger.warn("[anon_load_shed] flush failed: #{e.class}: #{e.message}")
      end
    end
  end
  private_class_method :start_flusher, :chrome_signal, :cookie_signal

  private

  # Counted, not traced. Query count(newrelic.timeslice.value) for Custom/AnonLoadShed/%.
  def record_shed(env)
    return unless defined?(NewRelic::Agent)
    NewRelic::Agent.ignore_transaction
    self.class.count_shed("Custom/AnonLoadShed/#{self.class.scraper_signal(env) || 'reader'}")
  rescue StandardError
    # Telemetry must never turn a shed into a 500.
    nil
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
  # RACK_ATTACK_SAFE_IP addresses, read the way Rack::Attack reads them.
  def safe_ip?(env)
    $safe_ips.present? && $safe_ips.include?(Rack::Request.new(env).ip)
  end

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
