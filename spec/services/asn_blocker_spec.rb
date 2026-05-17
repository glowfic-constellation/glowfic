RSpec.describe AsnBlocker do
  describe ".block?" do
    # The list of currently-blocked prefixes is loaded once at class load
    # from config/blocked_asn_cidrs.yml — pick a prefix that's present in
    # the seeded snapshot to assert on, and an unrelated one that isn't.

    it "blocks IPs inside a configured CIDR" do
      # 43.128.0.0/10 is one of the Tencent Cloud HK prefixes in the seeded list
      expect(described_class.block?('43.129.207.57')).to be(true)
    end

    it "doesn't block IPs outside the configured CIDRs" do
      expect(described_class.block?('8.8.8.8')).to be(false) # Google DNS
      expect(described_class.block?('1.1.1.1')).to be(false) # Cloudflare DNS
    end

    it "doesn't block IPs in deliberately excluded ASNs" do
      # AS16509 Amazon (e.g. an EC2 elastic IP) — excluded so embed traffic works
      expect(described_class.block?('54.239.28.85')).to be(false)
      # AS15169 Google — excluded so Googlebot keeps crawling
      expect(described_class.block?('142.250.80.46')).to be(false)
    end

    it "handles invalid IPs as not-blocked rather than raising" do
      expect(described_class.block?('not-an-ip')).to be(false)
      expect(described_class.block?('')).to be(false)
      expect(described_class.block?(nil)).to be(false)
    end
  end

  describe "loaded data" do
    it "loaded at least 1000 prefixes from the seeded snapshot" do
      expect(described_class::CIDRS.size).to be > 1000
    end

    it "bucketed IPv4 prefixes by first octet" do
      expect(described_class::IPV4_BY_FIRST_OCTET).to be_a(Hash)
      # 43.x range — Tencent — should have entries
      expect(described_class::IPV4_BY_FIRST_OCTET[43]).to be_present
    end
  end
end
