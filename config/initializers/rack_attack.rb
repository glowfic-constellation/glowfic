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

  # Blocklists here are deliberate denials (the hosting-ASN list and
  # RACK_ATTACK_BAD_IP), and 403 says exactly that. Rate limits go through
  # THROTTLED above, so a crawler that is only too fast always sees 429.
  BLOCKLISTED = lambda do |_req|
    [403, { 'content-type' => 'text/plain' }, ["Forbidden\n"]]
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
# The reply search API is not autocomplete: one request costs the same as one
# /replies/search page, so it stays in the same bucket as that page.
def autocomplete_api_request?(req)
  req.get? && req.path.start_with?('/api/v1/') && ['/api/v1/replies', '/api/v1/replies.json'].exclude?(req.path.chomp('/'))
end

# Calls an OAuth client makes from its own server: the token and OpenID Connect endpoints,
# and API calls with a bearer token. See app/services/oauth_request.rb.
def oauth_client_request?(req)
  OauthRequest.client?(req.path, req.get_header('HTTP_AUTHORIZATION'))
end

# Throttle anonymous, non-autocomplete traffic by IP. Tight ceiling here is the
# steady-state defence against scrapers — combined with the cluster-wide cache
# store this limit actually enforces fleet-wide (rather than per-worker).
# Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
# Autocomplete API GETs are excluded here and counted under 'api/ip' instead,
# and OAuth client requests under 'oauth/ip'.
Rack::Attack.throttle('req/ip', limit: ENV.fetch("RACK_ATTACK_IP_LIMIT", 25).to_i, period: 5.minutes) do |req|
  req.ip if !req_logged_in?(req) && !autocomplete_api_request?(req) && !oauth_client_request?(req)
end

# Throttle the read-only autocomplete API GETs by IP, with a higher limit since
# a single search legitimately generates many of them.
# Key: "rack::attack:#{Time.now.to_i/:period}:api/ip:#{req.ip}"
Rack::Attack.throttle('api/ip', limit: ENV.fetch("RACK_ATTACK_API_LIMIT", 150).to_i, period: 5.minutes) do |req|
  req.ip if !req_logged_in?(req) && autocomplete_api_request?(req) && !oauth_client_request?(req)
end

# One OAuth client's server makes these requests for all of its users, so it gets
# the logged-in user's ceiling rather than one anonymous reader's.
# Key: "rack::attack:#{Time.now.to_i/:period}:oauth/ip:#{req.ip}"
Rack::Attack.throttle('oauth/ip', limit: ENV.fetch("RACK_ATTACK_OAUTH_LIMIT", 1000).to_i, period: 5.minutes) do |req|
  req.ip if !req_logged_in?(req) && oauth_client_request?(req)
end

# Logged-in users get a much higher ceiling, keyed on user_id rather than IP,
# so multiple users behind a shared NAT (corporate proxy, mobile carrier,
# household) don't fight each other for the IP-based quota.
# Key: "rack::attack:#{Time.now.to_i/:period}:user:#{user_id}"
Rack::Attack.throttle('user', limit: ENV.fetch("RACK_ATTACK_USER_LIMIT", 1000).to_i, period: 5.minutes) do |req|
  if (uid = RequestUser.id(req.env))
    "user:#{uid}"
  end
end

# Throttle POST requests to /login by IP address to prevent brute force login attacks
# Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
Rack::Attack.throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/login' && req.post?
end

# Tell every throttled client how long to wait. See the responders at the top
# of this file for why Retry-After cannot be left to rack-attack's own setting.
Rack::Attack.throttled_responder = RackAttackResponders::THROTTLED
Rack::Attack.blocklisted_responder = RackAttackResponders::BLOCKLISTED

# Counts "remember me" readers whose session cookie is gone as logged in, so
# the ASN blocklist and IP throttles don't turn them away before a controller
# can restore their session. See RequestUser.
def req_logged_in?(req)
  RequestUser.id(req.env).present?
end

# Block requests from hosting / cloud-provider ASNs whose IP space carries
# effectively zero legitimate end-user traffic to glowfic (see
# config/blocked_asns.yml and config/blocked_asn_cidrs.yml). Logged-in users
# and explicitly safelisted IPs are exempt. This catches distributed scrapers
# that rotate across many cloud IPs in the same ASN — a class of abuse the
# per-IP throttle can't address. OAuth clients are exempt too: their servers
# are on hosting providers, and these requests serve no posts to a scraper.
Rack::Attack.blocklist('bad_asn') do |req|
  next false if req_logged_in?(req) || oauth_client_request?(req)
  AsnBlocker.block?(req.ip)
end

