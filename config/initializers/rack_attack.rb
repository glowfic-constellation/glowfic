# frozen_string_literal: true
return unless Rails.env.production?

# allow all IPs in RACK_ATTACK_SAFE_IP split by comma
safe_ips = ENV.fetch("RACK_ATTACK_SAFE_IP", "").split(",").compact_blank
safe_ips.each { |ip| Rack::Attack.safelist_ip(ip) }

# block all IPs in RACK_ATTACK_BAD_IP split by comma
ENV.fetch("RACK_ATTACK_BAD_IP", "").split(",").compact_blank.each { |ip| Rack::Attack.blocklist_ip(ip) }

# Configure Cache
url = ENV.fetch("HEROKU_REDIS_TEAL_URL", nil)
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new(url: url, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }) if url

# Throttle all requests by IP (60rpm)
# Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
Rack::Attack.throttle('req/ip', limit: ENV.fetch("RACK_ATTACK_IP_LIMIT", 25).to_i, period: 5.minutes, &:ip)

# Throttle POST requests to /login by IP address to prevent brute force login attacks
# Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
Rack::Attack.throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
  req.ip if req.path == '/login' && req.post?
end

# Return to user how many seconds to wait until they can start sending requests again
Rack::Attack.throttled_response_retry_after_header = true

# Includes conventional RateLimit-* headers for safe IPs:
Rack::Attack.throttled_responder = lambda do |req|
  return [429, {}, ["Throttled\n"]] unless safe_ips.include?(req.ip)

  match_data = req.env['rack.attack.match_data']
  now = match_data[:epoch_time]

  headers = {
    'RateLimit-Limit'     => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset'     => (now + match_data[:period] - (now % match_data[:period])).to_s,
  }

  [429, headers, ["Throttled\n"]]
end
