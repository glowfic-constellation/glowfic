# frozen_string_literal: true
return unless Rails.env.production?

# allow all IPs in RACK_ATTACK_SAFE_IP split by comma
safe_ips = ENV.fetch("RACK_ATTACK_SAFE_IP", "").split(",")
safe_ips.each do |ip|
  next if ip == ""
  Rack::Attack.safelist_ip(ip)
end

# block all IPs in RACK_ATTACK_BAD_IP split by comma
ENV.fetch("RACK_ATTACK_BAD_IP", "").split(",").each do |ip|
  next if ip == ""
  Rack::Attack.blocklist_ip(ip)
end

class Rack::Attack
  # Configure Cache
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new # TODO is this right

  # Throttle all requests by IP (60rpm)
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Throttle POST requests to /login by IP address to prevent brute force login attacks
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end

  # Return to user how many seconds to wait until they can start sending requests again
  Rack::Attack.throttled_response_retry_after_header = true

  # Includes conventional RateLimit-* headers for safe IPs:
  Rack::Attack.throttled_responder = lambda do |req|
    return [ 429, {}, ["Throttled\n"]] unless safe_ips.include?(req.ip)

    match_data = req.env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => '0',
      'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
    }

    [ 429, headers, ["Throttled\n"]]
  end
end