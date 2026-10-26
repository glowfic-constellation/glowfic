# frozen_string_literal: true
# The RACK_ATTACK_SAFE_IP and RACK_ATTACK_BAD_IP lists for Rack::Attack.
#
# rack-attack's own safelist_ip and blocklist_ip skip an empty client IP but pass
# any other value to IPAddr.new, which raises on one that isn't an address, such as
# a forged X-Forwarded-For of "unknown" or an address with a port. That was a 500
# for the request. Here an invalid client IP just doesn't match.
class RackAttackIpList
  class << self
    def safe?(address)
      match?(safe_ranges, address)
    end

    def bad?(address)
      match?(bad_ranges, address)
    end

    # Comma-separated addresses or CIDR ranges; blanks and spaces are ignored.
    def parse(list)
      list.to_s.split(",").map(&:strip).compact_blank.map { |entry| IPAddr.new(entry) }
    end

    def match?(ranges, address)
      return false if ranges.empty? || address.blank?
      client = IPAddr.new(address)
      ranges.any? { |range| range.include?(client) }
    rescue IPAddr::InvalidAddressError
      false
    end

    private

    def safe_ranges
      @safe_ranges ||= parse(ENV.fetch("RACK_ATTACK_SAFE_IP", ""))
    end

    def bad_ranges
      @bad_ranges ||= parse(ENV.fetch("RACK_ATTACK_BAD_IP", ""))
    end
  end
end
