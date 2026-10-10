RSpec.describe AsnBlocker do
  describe ".block?" do
    # The list of currently-blocked prefixes is loaded once at class load
    # from config/blocked_asn_cidrs.yml — pick a prefix that's present in
    # the seeded snapshot to assert on, and an unrelated one that isn't.

    it "blocks IPs inside a configured CIDR" do
      # covered by 43.129.0.0/16, one of the Tencent Cloud HK prefixes in the seeded list
      expect(AsnBlocker.block?('43.129.207.57')).to be(true)
    end

    it "doesn't block IPs outside the configured CIDRs" do
      expect(AsnBlocker.block?('8.8.8.8')).to be(false) # Google DNS
      expect(AsnBlocker.block?('1.1.1.1')).to be(false) # Cloudflare DNS
    end

    it "doesn't block IPs in deliberately excluded ASNs" do
      # AS16509 Amazon (e.g. an EC2 elastic IP) — excluded so embed traffic works
      expect(AsnBlocker.block?('54.239.28.85')).to be(false)
      # AS15169 Google — excluded so Googlebot keeps crawling
      expect(AsnBlocker.block?('142.250.80.46')).to be(false)
    end

    it "handles invalid IPs as not-blocked rather than raising" do
      expect(AsnBlocker.block?('not-an-ip')).to be(false)
      expect(AsnBlocker.block?('')).to be(false)
      expect(AsnBlocker.block?(nil)).to be(false)
    end
  end

  describe ".block? range boundaries" do
    before(:each) do
      stub_const("AsnBlocker::IPV4_RANGES", [[IPAddr.new('10.0.0.0').to_i, IPAddr.new('10.0.0.255').to_i]])
      stub_const("AsnBlocker::IPV6_RANGES", [[IPAddr.new('2001:db8::').to_i, IPAddr.new('2001:db8::ffff').to_i]])
    end

    it "blocks the first and last address of a range" do
      expect(AsnBlocker.block?('10.0.0.0')).to be(true)
      expect(AsnBlocker.block?('10.0.0.255')).to be(true)
      expect(AsnBlocker.block?('2001:db8::')).to be(true)
      expect(AsnBlocker.block?('2001:db8::ffff')).to be(true)
    end

    it "doesn't block addresses just outside a range" do
      expect(AsnBlocker.block?('9.255.255.255')).to be(false)
      expect(AsnBlocker.block?('10.0.1.0')).to be(false)
      expect(AsnBlocker.block?('2001:db8::1:0')).to be(false)
    end

    it "checks IPv4-mapped IPv6 addresses against the IPv4 ranges" do
      expect(AsnBlocker.block?('::ffff:10.0.0.1')).to be(true)
      expect(AsnBlocker.block?('::ffff:10.0.1.0')).to be(false)
    end
  end

  describe ".collapse" do
    it "drops prefixes contained in others" do
      expect(AsnBlocker.collapse(['10.0.0.0/8', '10.1.0.0/16'])).to eq(['10.0.0.0/8'])
    end

    it "merges adjacent prefixes into their supernet" do
      expect(AsnBlocker.collapse(['10.0.1.0/24', '10.0.0.0/24'])).to eq(['10.0.0.0/23'])
    end

    it "splits merged ranges that don't align to a single CIDR" do
      expect(AsnBlocker.collapse(['10.0.1.0/24', '10.0.2.0/24'])).to eq(['10.0.1.0/24', '10.0.2.0/24'])
    end

    it "sorts numerically with IPv4 before IPv6" do
      prefixes = ['2001:db8::/32', '100.0.0.0/8', '9.0.0.0/8']
      expect(AsnBlocker.collapse(prefixes)).to eq(['9.0.0.0/8', '100.0.0.0/8', '2001:db8::/32'])
    end
  end

  describe "loaded data" do
    it "loaded ranges from the seeded snapshot" do
      expect(described_class::IPV4_RANGES.size).to be > 1000
      expect(described_class::IPV6_RANGES).to be_present
    end
  end
end
