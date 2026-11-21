RSpec.describe SignupFormToken do
  it "accepts a token between the minimum and maximum age" do
    expect(SignupFormToken.valid?(SignupFormToken.generate(issued: 1.minute.ago))).to be(true)
  end

  it "rejects missing, forged, too-fresh and expired tokens" do
    expect(SignupFormToken.valid?(nil)).to be(false)
    expect(SignupFormToken.valid?('forged')).to be(false)
    expect(SignupFormToken.valid?(SignupFormToken.generate)).to be(false)
    expect(SignupFormToken.valid?(SignupFormToken.generate(issued: 2.days.ago))).to be(false)
  end
end
