require "rails_helper"

RSpec.describe Glowfic::BuiltinSkins do
  # Stub out asset compilation so the spec does not depend on the pipeline.
  let(:loader) { ->(slug) { ".x { color: red !important; } /* #{slug} */" } }

  it "seeds each built-in layout as a pre-approved public skin" do
    owner = create(:admin_user)

    created = Glowfic::BuiltinSkins.seed!(owner: owner, css_loader: loader)

    expect(created).to eq(described_class::LAYOUTS.size)
    skins = owner.skins
    expect(skins.count).to eq(described_class::LAYOUTS.size)
    skins.each do |skin|
      expect(skin.public).to be(true)
      expect(skin.approved?).to be(true)
      expect(skin.approved_by).to eq(owner)
      # pre-approved, so a reader gets the raw CSS
      expect(skin.css_for(create(:user))).to include('!important')
    end
  end

  it "is idempotent" do
    owner = create(:admin_user)
    Glowfic::BuiltinSkins.seed!(owner: owner, css_loader: loader)
    expect {
      expect(Glowfic::BuiltinSkins.seed!(owner: owner, css_loader: loader)).to eq(0)
    }.not_to change { Skin.count }
  end

  it "skips a layout whose CSS cannot be loaded" do
    owner = create(:admin_user)
    blank_loader = ->(_slug) {}
    expect(Glowfic::BuiltinSkins.seed!(owner: owner, css_loader: blank_loader)).to eq(0)
    expect(Skin.count).to eq(0)
  end

  it "defaults the owner to an admin" do
    admin = create(:admin_user)
    create(:user)
    expect(Glowfic::BuiltinSkins.default_owner).to eq(admin)
  end
end
