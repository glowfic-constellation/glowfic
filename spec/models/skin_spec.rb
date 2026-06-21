require "rails_helper"

RSpec.describe Skin do
  it "requires a name and an owner" do
    skin = Skin.new(css: '.a { color: red; }')
    expect(skin).not_to be_valid
    expect(skin.errors.attribute_names).to include(:name, :user)
  end

  it "stores the sanitized CSS alongside the raw CSS on save" do
    skin = create(:skin, css: '.post-container { color: red !important; background: url(https://evil.example/x); }')
    expect(skin.css).to include('!important') # raw is preserved for editing
    expect(skin.sanitized_css).to include('color: red')
    expect(skin.sanitized_css).not_to include('!important')
    expect(skin.sanitized_css).not_to include('evil.example')
  end

  it "recomputes sanitized CSS when the CSS changes" do
    skin = create(:skin, css: '.a { color: red; }')
    skin.update!(css: '.a { color: blue; }')
    expect(skin.sanitized_css).to include('color: blue')
    expect(skin.sanitized_css).not_to include('color: red')
  end

  it "rejects CSS over the maximum length" do
    skin = build(:skin, css: 'a' * (Glowfic::CssSanitizer::MAX_LENGTH + 1))
    expect(skin).not_to be_valid
    expect(skin.errors.attribute_names).to include(:css)
  end

  describe "scopes" do
    it ".listed returns only public skins" do
      public_skin = create(:skin, public: true)
      create(:skin, public: false)
      expect(Skin.listed).to eq([public_skin])
    end
  end
end
