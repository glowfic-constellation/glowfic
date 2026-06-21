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

  describe "permissions" do
    let(:owner) { create(:user) }

    it "is only editable by its owner" do
      skin = create(:skin, user: owner)
      expect(skin.editable_by?(owner)).to be(true)
      expect(skin.editable_by?(create(:user))).to be(false)
      expect(skin.editable_by?(nil)).to be(false)
    end

    it "is visible to anyone when public, otherwise only its owner" do
      public_skin = create(:skin, user: owner, public: true)
      private_skin = create(:skin, user: owner, public: false)
      expect(public_skin.visible_to?(nil)).to be(true)
      expect(private_skin.visible_to?(nil)).to be(false)
      expect(private_skin.visible_to?(create(:user))).to be(false)
      expect(private_skin.visible_to?(owner)).to be(true)
    end
  end

  describe "scopes" do
    it ".listed surfaces safe and approved public skins but hides pending dangerous ones" do
      safe = create(:skin, public: true, css: '.a { color: red; }')
      pending = create(:skin, public: true, css: '.a { color: red !important; }')
      approved = create(:skin, public: true, css: '.a { color: blue !important; }')
      approved.approve!(create(:mod_user))
      create(:skin, public: false)

      expect(Skin.listed).to match_array([safe, approved])
      expect(Skin.pending_review).to eq([pending])
    end

    it ".pending_review also includes a private skin recommended on a post" do
      recommended = create(:skin, public: false, css: '.a { color: red !important; }')
      create(:post, skin: recommended)
      expect(Skin.pending_review).to include(recommended)
    end
  end

  describe "versioning and approval" do
    it "is audited" do
      skin = create(:skin)
      expect { skin.update!(name: 'Renamed') }.to change { skin.audits.count }.by(1)
    end

    it "flags dangerous CSS (and caches it for scopes)" do
      expect(build(:skin, css: '.a { color: red; }').dangerous?).to be(false)
      expect(build(:skin, css: '.a { position: fixed; }').dangerous?).to be(true)
      expect(create(:skin, css: '.a { position: fixed; }').dangerous).to be(true)
    end

    it "serves raw CSS to the owner but the safe version to others until approved" do
      owner = create(:user)
      reader = create(:user)
      skin = create(:skin, user: owner, css: '.a { color: red !important; }')

      expect(skin.css_for(owner)).to include('!important')
      expect(skin.css_for(reader)).not_to include('!important')

      skin.approve!(create(:mod_user))
      expect(skin.css_for(reader)).to include('!important')
    end

    it "lapses approval when the CSS changes" do
      skin = create(:skin, css: '.a { color: red !important; }')
      skin.approve!(create(:mod_user))
      expect(skin.approved?).to be(true)

      skin.update!(css: '.a { color: blue !important; }')
      expect(skin.approved?).to be(false)
      expect(skin.reload.approved_at).to be_nil
    end

    it "allows publishing safe CSS without review" do
      expect(build(:skin, public: true, css: '.a { color: red; }')).to be_valid
    end
  end
end
