# frozen_string_literal: true

# Checks whether a given IP belongs to a hosting / cloud-provider ASN whose
# traffic to glowfic is overwhelmingly automated.
#
# The CIDR list (config/blocked_asn_cidrs.yml) is loaded once at boot and
# merged into sorted, non-overlapping integer ranges per address family, so a
# lookup is a single binary search for both IPv4 and IPv6.
class AsnBlocker
  CIDR_FILE = Rails.root.join('config', "blocked_asn_cidrs.yml").freeze

  class << self
    def block?(address)
      return false if address.blank?

      # native turns IPv4-mapped IPv6 (::ffff:a.b.c.d) back into plain IPv4
      addr = IPAddr.new(address.to_s).native
      ranges = addr.ipv4? ? IPV4_RANGES : IPV6_RANGES
      ip = addr.to_i
      # the only range that can contain ip is the last one starting at or before it
      index = (ranges.bsearch_index { |lo, _hi| lo > ip } || ranges.size) - 1
      index >= 0 && ip <= ranges[index][1]
    rescue IPAddr::InvalidAddressError
      false
    end

    # Reduces a list of prefixes to the minimal set of CIDRs covering the same
    # addresses, sorted numerically with IPv4 before IPv6. RIPEstat returns many
    # overlapping and adjacent more-specifics, so this shrinks the list a lot.
    def collapse(prefixes)
      ipv4, ipv6 = prefixes.map { |p| IPAddr.new(p) }.partition(&:ipv4?)
      merge_ranges(ipv4).flat_map { |lo, hi| range_to_cidrs(lo, hi, Socket::AF_INET) } +
        merge_ranges(ipv6).flat_map { |lo, hi| range_to_cidrs(lo, hi, Socket::AF_INET6) }
    end

    private

    def merge_ranges(nets)
      nets.map { |net| net.to_range.then { |range| [range.first.to_i, range.last.to_i] } }.sort.each_with_object([]) do |(lo, hi), merged|
        if merged.any? && lo <= merged.last[1] + 1
          merged.last[1] = [merged.last[1], hi].max
        else
          merged << [lo, hi]
        end
      end
    end

    def range_to_cidrs(first, last, family)
      max_bits = family == Socket::AF_INET ? 32 : 128
      cidrs = []
      while first <= last
        # largest block aligned at first (trailing zero bits) that doesn't overrun last
        size = first.zero? ? max_bits : (first & -first).bit_length - 1
        size -= 1 while first + (1 << size) - 1 > last
        cidrs << "#{IPAddr.new(first, family)}/#{max_bits - size}"
        first += 1 << size
      end
      cidrs
    end
  end

  IPV4_RANGES, IPV6_RANGES = begin
    nets = (YAML.load_file(CIDR_FILE)['prefixes'] || []).map { |p| IPAddr.new(p) }
    nets.partition(&:ipv4?).map { |family| merge_ranges(family).each(&:freeze).freeze }
  rescue Errno::ENOENT
    [[].freeze, [].freeze]
  end
end
