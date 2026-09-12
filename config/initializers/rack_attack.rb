# frozen_string_literal: true

# The responses this app sends when a client is asking for too much.
#
# Crawlers read these as instructions, and the codes are not interchangeable.
# Google reduces its crawl rate on 429 and 503 and backs off on Retry-After;
# 403 and 404 mean the URL is gone for good, so answering a rate limit with
# one is how a site gets dropped from an index rather than merely slowed
# down. Bing reduces its rate on 429 but ignores Retry-After entirely, which
# is why bingbot also gets a Crawl-delay in public/robots.txt.
#
# Defined above the production guard below so they can be exercised in specs;
# only the wiring into Rack::Attack is production-only.
module RackAttackResponders
  ALLOW2BAN_NAME = 'allow2ban bots'

  # The two allow2ban bans further down. Retry-After on a ban advertises the
  # shorter of them: a client that comes back too early just gets the header
  # again, which is the loop backing off is supposed to take.
  SHORT_BAN = 1.hour
  LONG_BAN = 1.day

  # rack-attack's `throttled_response_retry_after_header` setting is read only
  # inside its DEFAULT_THROTTLED_RESPONDER, so it silently stops doing
  # anything the moment a custom responder is assigned — as one is here.
  # Retry-After has to be set by hand, or not one 429 this app sends carries
  # the single header that tells a client how long to wait.
  THROTTLED = lambda do |req|
    match_data = req.env['rack.attack.match_data']
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    headers = { 'content-type' => 'text/plain', 'retry-after' => retry_after.to_s }

    # RateLimit-* describes a quota, which only means something to a client
    # that knows it has one: our own safelisted callers and the documented
    # API. Retry-After above is the part every other client understands.
    if $safe_ips.include?(req.ip) || req.path.starts_with?('/api')
      headers['ratelimit-limit'] = match_data[:limit].to_s
      headers['ratelimit-remaining'] = '0'
      headers['ratelimit-reset'] = (now + retry_after).to_s
    end

    [429, headers, ["Throttled\n"]]
  end

  # A ban earned by request rate is temporary and the client should be told
  # when to return; an IP on the explicit RACK_ATTACK_BAD_IP list is not
  # welcome at all, and 403 says exactly that.
  #
  # Answering the rate-earned ban with 403 was measurably counterproductive:
  # in the seven days to 2026-09-09 ClaudeBot took 625,122 of them and never
  # backed off, because 403 carries no notion of trying again later.
  #
  # rack-attack records the matched rule's name here, and `blocklist_ip`
  # builds an anonymous blocklist, so the manual list leaves it nil.
  BLOCKLISTED = lambda do |req|
    return [403, { 'content-type' => 'text/plain' }, ["Forbidden\n"]] unless req.env['rack.attack.matched'] == ALLOW2BAN_NAME

    [429, { 'content-type' => 'text/plain', 'retry-after' => SHORT_BAN.to_i.to_s }, ["Throttled\n"]]
  end
end

$safe_ips = [] and return unless Rails.env.production?

# allow all IPs in RACK_ATTACK_SAFE_IP split by comma
$safe_ips = ENV.fetch("RACK_ATTACK_SAFE_IP", "").split(",").compact_blank
$safe_ips.each { |ip| Rack::Attack.safelist_ip(ip) }

# block all IPs in RACK_ATTACK_BAD_IP split by comma
ENV.fetch("RACK_ATTACK_BAD_IP", "").split(",").compact_blank.each { |ip| Rack::Attack.blocklist_ip(ip) }

# Configure Cache
# Rack::Attack stores its throttle/blocklist counters here. This needs to be
# a backend that's shared across every Puma worker on every dyno; otherwise
# each worker keeps its own in-process counter and the configured limit is
# multiplied by `WEB_CONCURRENCY * dyno_count`.
url = ENV.fetch("HEROKU_REDIS_TEAL_URL", nil)
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) if url

# Read-only API GETs power the search forms' autocomplete dropdowns (select2).
# A single search interaction fans out into many of these requests - one per
# dropdown opened and one per keystroke - which is fundamentally different from
# normal page browsing (~1 request per navigation). They get their own, more
# generous bucket below so a search doesn't exhaust the general per-IP limit.
def autocomplete_api_request?(req)
  req.get? && req.path.start_with?('/api/v1/')
end

# Throttle anonymous, non-autocomplete traffic by IP. Tight ceiling here is the
# steady-state defence against scrapers — combined with the cluster-wide cache
# store this limit actually enforces fleet-wide (rather than per-worker).
# Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
# Autocomplete API GETs are excluded here and counted under 'api/ip' instead.
Rack::Attack.throttle('req/ip', limit: ENV.fetch("RACK_ATTACK_IP_LIMIT", 25).to_i, period: 5.minutes) do |req|
  req.ip if !req_logged_in?(req) && !autocomplete_api_request?(req)
end

# Throttle the read-only autocomplete API GETs by IP, with a higher limit since
# a single search legitimately generates many of them.
# Key: "rack::attack:#{Time.now.to_i/:period}:api/ip:#{req.ip}"
Rack::Attack.throttle('api/ip', limit: ENV.fetch("RACK_ATTACK_API_LIMIT", 150).to_i, period: 5.minutes) do |req|
  req.ip if !req_logged_in?(req) && autocomplete_api_request?(req)
end

# Logged-in users get a much higher ceiling, keyed on user_id rather than IP,
# so multiple users behind a shared NAT (corporate proxy, mobile carrier,
# household) don't fight each other for the IP-based quota.
# Key: "rack::attack:#{Time.now.to_i/:period}:user:#{user_id}"
Rack::Attack.throttle('user', limit: ENV.fetch("RACK_ATTACK_USER_LIMIT", 1000).to_i, period: 5.minutes) do |req|
  if (uid = req.session[:user_id])
    "user:#{uid}"
  end
end

# Throttle POST requests to /login by IP address to prevent brute force login attacks
# Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
Rack::Attack.throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/login' && req.post?
end

# Tell every throttled and banned client how long to wait. See the responders
# at the top of this file for why Retry-After cannot be left to rack-attack's
# own setting, and why a rate-earned ban answers 429 rather than 403.
Rack::Attack.throttled_responder = RackAttackResponders::THROTTLED
Rack::Attack.blocklisted_responder = RackAttackResponders::BLOCKLISTED

def req_logged_in?(req)
  req.session[:user_id].present?
end

# Lockout IP addresses that are hammering the app.
Rack::Attack.blocklist(RackAttackResponders::ALLOW2BAN_NAME) do |req|
  next false if req_logged_in?(req)

  minute_limit = ENV.fetch("RACK_ATTACK_IP_LIMIT", 25).to_i

  # ban anyone at 5x the rate of our throttle limit per minute unless logged in or using API
  Rack::Attack::Allow2Ban.filter("minute:#{req.ip}", maxretry: minute_limit, findtime: 1.minute, bantime: RackAttackResponders::SHORT_BAN) do
    !req.path.starts_with?('/api')
  end

  # ban anyone at our throttle limit for the duration of an hour unless logged in or using API
  Rack::Attack::Allow2Ban.filter("hour:#{req.ip}", maxretry: minute_limit * 60, findtime: 1.hour, bantime: RackAttackResponders::LONG_BAN) do
    !req.path.starts_with?('/api')
  end
end
