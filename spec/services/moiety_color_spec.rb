RSpec.describe MoietyColor do
  # Reference values from the hsluv JS library the moiety explorer uses (lch_l, lch_c, lch_h)
  {
    'ff0000' => [53.2371, 179.0381, 12.1771],
    '4d7fff' => [56.0631, 112.6189, 259.0341],
    '00ff00' => [87.7355, 135.7895, 127.7150],
    'aabbcc' => [75.1053, 18.5984, 237.8523],
  }.each do |hex, (lightness, chroma, hue)|
    it "matches hsluv for ##{hex}" do
      color = MoietyColor.new(hex)
      expect(color.lightness).to be_within(0.001).of(lightness)
      expect(color.chroma).to be_within(0.001).of(chroma)
      expect(color.hue).to be_within(0.001).of(hue)
    end
  end

  it "expands three-digit codes" do
    expect(MoietyColor.new('abc').hue).to be_within(0.001).of(MoietyColor.new('aabbcc').hue)
  end

  it "accepts a leading # and any case" do
    expect(MoietyColor.new('#4D7FFF').hue).to be_within(0.001).of(259.0341)
  end

  it "treats black, white and grays as gray" do
    expect(%w(000000 ffffff 808080 777).map { |hex| MoietyColor.new(hex).gray? }).to all(be(true))
    expect(MoietyColor.new('4d7fff').gray?).to be(false)
  end

  it "rejects anything that isn't a hex color" do
    expect { MoietyColor.new('blue') }.to raise_error(ArgumentError)
  end

  describe ".sort_key_for" do
    it "orders hues around the wheel, then grays light to dark, then unparseable codes" do
      hexes = %w(blue 000000 4d7fff ffffff 00ff00 ff0000 808080)
      expect(hexes.sort_by { |hex| MoietyColor.sort_key_for(hex) }).to eq(%w(ff0000 00ff00 4d7fff ffffff 808080 000000 blue))
    end

    it "puts lighter colors first within a hue" do
      expect(%w(800000 ff0000).sort_by { |hex| MoietyColor.sort_key_for(hex) }).to eq(%w(ff0000 800000))
    end
  end
end
