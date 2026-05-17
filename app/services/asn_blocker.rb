# frozen_string_literal: true

# Checks whether a given IP belongs to a hosting / cloud-provider ASN whose
# traffic to glowfic is overwhelmingly automated.
#
# The CIDR list (config/blocked_asn_cidrs.yml) is loaded once at boot and
# bucketed by IPv4 first-octet for sub-millisecond lookups against the
# ~10k IPv4 prefixes typical for the configured ASN set. IPv6 prefixes
# fall through to a linear scan (smaller list, less frequent traffic).
class AsnBlocker
  CIDR_FILE = Rails.root.join('config/blocked_asn_cidrs.yml').freeze

  CIDRS = begin
    data = YAML.load_file(CIDR_FILE)
    (data['prefixes'] || []).map { |p| IPAddr.new(p) }.freeze
  rescue Errno::ENOENT
    [].freeze
  end

  # All IPv4 prefixes in the seeded snapshot are >= /13, so each CIDR fits
  # entirely within one first-octet bucket and a single Hash lookup narrows
  # the candidate set from ~10k to typically <100 before the per-CIDR check.
  IPV4_BY_FIRST_OCTET = CIDRS
    .select(&:ipv4?)
    .group_by { |cidr| (cidr.to_i >> 24) & 0xff }
    .each_value(&:freeze)
    .freeze

  IPV6_CIDRS = CIDRS.reject(&:ipv4?).freeze

  def self.block?(ip)
    return false if ip.blank?

    addr = IPAddr.new(ip.to_s)
    if addr.ipv4?
      bucket = IPV4_BY_FIRST_OCTET[(addr.to_i >> 24) & 0xff]
      bucket && bucket.any? { |cidr| cidr.include?(addr) }
    else
      IPV6_CIDRS.any? { |cidr| cidr.include?(addr) }
    end
  rescue IPAddr::InvalidAddressError
    false
  end
end
