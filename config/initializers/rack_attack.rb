# frozen_string_literal: true
return unless Rails.env.production?

# allow all IPs in RACK_ATTACK_SAFE_IP split by comma
ENV.fetch("RACK_ATTACK_SAFE_IP", "").split(",").each do |ip|
  next if ip == ""
  Rack::Attack.safelist_ip(ip)
end

# block all IPs in RACK_ATTACK_BAD_IP split by comma
ENV.fetch("RACK_ATTACK_BAD_IP", "").split(",").each do |ip|
  next if ip == ""
  Rack::Attack.blocklist_ip(ip)
end
