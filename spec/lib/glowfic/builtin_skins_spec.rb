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

  it "falls back to the first user when there is no admin" do
    first = create(:user)
    create(:user)
    expect(Glowfic::BuiltinSkins.default_owner).to eq(first)
  end

  it "does nothing (and logs) when there is no user to own the skins" do
    messages = []
    created = Glowfic::BuiltinSkins.seed!(owner: nil, css_loader: loader, logger: ->(m) { messages << m })
    expect(created).to eq(0)
    expect(messages.first).to match(/No user available/)
    expect(Skin.count).to eq(0)
  end

  it "logs and skips a layout whose CSS will not load" do
    owner = create(:admin_user)
    messages = []
    Glowfic::BuiltinSkins.seed!(owner: owner, css_loader: ->(_slug) {}, logger: ->(m) { messages << m })
    expect(messages).to include(a_string_matching(/Could not load CSS/))
  end

  describe ".compiled_css" do
    it "loads bundled layout CSS through the asset pipeline without raising" do
      expect { Glowfic::BuiltinSkins.compiled_css('dark') }.not_to raise_error
      css = Glowfic::BuiltinSkins.compiled_css('dark')
      expect(css).to be_a(String).or be_nil
    end

    context "when running from a precompiled manifest (no live Sprockets)" do
      before { allow(Rails.application).to receive(:assets).and_return(nil) }

      it "returns nil when the layout is not in the manifest" do
        manifest = instance_double('manifest', assets: {})
        allow(Rails.application).to receive(:assets_manifest).and_return(manifest)
        expect(Glowfic::BuiltinSkins.compiled_css('dark')).to be_nil
      end

      it "reads the digest-stamped file from the manifest" do
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, 'dark-abc123.css'), '.dark { color: #fff; }')
          manifest = instance_double('manifest', assets: { 'layouts/dark.css' => 'dark-abc123.css' }, dir: dir)
          allow(Rails.application).to receive(:assets_manifest).and_return(manifest)
          expect(Glowfic::BuiltinSkins.compiled_css('dark')).to include('.dark { color: #fff; }')
        end
      end
    end
  end
end
