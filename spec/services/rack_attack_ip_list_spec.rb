RSpec.describe RackAttackIpList do
  let(:ranges) { RackAttackIpList.parse("203.0.113.5, 198.51.100.0/24,,2001:db8::/32") }

  describe ".parse" do
    it "parses a comma-separated list, ignoring blanks and spaces" do
      expect(ranges.map { |range| range.to_range.first.to_s }).to eq(["203.0.113.5", "198.51.100.0", "2001:db8::"])
    end

    it "is empty for an empty list" do
      expect(RackAttackIpList.parse("")).to eq([])
    end
  end

  describe ".match?" do
    it "matches a listed address and an address inside a listed range" do
      expect(RackAttackIpList.match?(ranges, "203.0.113.5")).to be(true)
      expect(RackAttackIpList.match?(ranges, "198.51.100.77")).to be(true)
      expect(RackAttackIpList.match?(ranges, "2001:db8::1")).to be(true)
    end

    it "does not match other addresses" do
      expect(RackAttackIpList.match?(ranges, "203.0.113.6")).to be(false)
      expect(RackAttackIpList.match?(ranges, "2001:db9::1")).to be(false)
    end

    # rack-attack's safelist_ip raised IPAddr::InvalidAddressError on these, which was a 500.
    it "treats a client IP that isn't an address as no match" do
      ["unknown", "203.0.113.5:443", "[]", " "].each do |address|
        expect(RackAttackIpList.match?(ranges, address)).to be(false)
      end
    end

    it "does not match a missing client IP or an empty list" do
      expect(RackAttackIpList.match?(ranges, nil)).to be(false)
      expect(RackAttackIpList.match?([], "203.0.113.5")).to be(false)
    end
  end

  describe ".safe? and .bad?" do
    around(:each) do |example|
      RackAttackIpList.instance_variable_set(:@safe_ranges, nil)
      RackAttackIpList.instance_variable_set(:@bad_ranges, nil)
      example.run
      RackAttackIpList.instance_variable_set(:@safe_ranges, nil)
      RackAttackIpList.instance_variable_set(:@bad_ranges, nil)
    end

    it "reads the lists from the environment" do
      stub_const("ENV", ENV.to_h.merge("RACK_ATTACK_SAFE_IP" => "203.0.113.5", "RACK_ATTACK_BAD_IP" => "198.51.100.0/24"))
      expect(RackAttackIpList.safe?("203.0.113.5")).to be(true)
      expect(RackAttackIpList.bad?("198.51.100.9")).to be(true)
      expect(RackAttackIpList.safe?("unknown")).to be(false)
    end
  end
end
