require "spec_helper"

RSpec.describe Character do
  describe "validations" do
    it "requires valid group" do
      character = build(:character)
      expect(character).to be_valid
      character.character_group_id = 0
      expect(character).not_to be_valid
    end

    it "requires valid default icon" do
      icon = create(:icon)
      character = build(:character)
      expect(character).to be_valid
      character.default_icon = icon
      expect(character).not_to be_valid
    end

    it "requires valid galleries" do
      gallery = create(:gallery)
      character = create(:character)
      expect(character).to be_valid
      character.gallery_ids = [gallery.id]
      expect(character).not_to be_valid
    end

    it "strips facecast" do
      character = create(:character, pb: 'Chris Pine ')
      expect(character.reload.pb).to eq('Chris Pine')
    end
  end

  it "uniqs gallery images" do
    character = create(:character)
    icon = create(:icon, user: character.user)
    gallery = create(:gallery, user: character.user)
    gallery.icons << icon
    expect(gallery.icons.map(&:id)).to eq([icon.id])
    character.galleries << gallery
    gallery = create(:gallery, user: character.user)
    gallery.icons << icon
    expect(gallery.icons.map(&:id)).to eq([icon.id])
    character.galleries << gallery
    expect(character.galleries.size).to eq(2)
    expect(character.icons.map(&:id)).to eq([icon.id])
  end

  describe "#editable_by?" do
    it "should be false for random user" do
      character = create(:character)
      user = create(:user)
      expect(character).not_to be_editable_by(user)
    end

    it "should be true for owner" do
      character = create(:character)
      expect(character).to be_editable_by(character.user)
    end

    it "should be true for admin" do
      character = create(:character)
      admin = create(:admin_user)
      expect(character).to be_editable_by(admin)
    end
  end

  describe "#ungrouped_gallery_ids" do
    it "returns only galleries not added by groups" do
      user = create(:user)
      character = create(:character, user: user)
      gallery1 = create(:gallery, user: user)
      gallery2 = create(:gallery, user: user)

      CharactersGallery.create!(character: character, gallery: gallery1)
      CharactersGallery.create!(character: character, gallery: gallery2, added_by_group: true)

      character.reload
      expect(character.gallery_ids).to match_array([gallery1.id, gallery2.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery1.id])
    end
  end

  describe "audits" do
    before(:each) do
      Character.auditing_enabled = true
      expect(Audited::Audit.count).to eq(0)
    end
    after(:each) { Character.auditing_enabled = false }

    it "is not created on create" do
      create(:character)
      Audited.audit_class.as_user(create(:user)) { create(:character) }
      expect(Audited::Audit.count).to eq(0)
    end

    it "is only created on mod update" do
      character = create(:character)
      Audited.audit_class.as_user(character.user) do
        character.update(name: character.name + 'notmod')
      end
      Audited.audit_class.as_user(create(:user)) do
        character.update(name: character.name + 'mod', audit_comment: 'mod')
      end
      expect(Audited::Audit.count).to eq(1)
    end

    it "is not created on destroy" do
      character = create(:character)
      Audited.audit_class.as_user(create(:user)) do
        character.destroy
      end
      expect(Audited::Audit.count).to eq(0)
    end
  end

  describe "#galleries" do
    it "updates order when adding galleries" do
      user = create(:user)
      gallery1 = create(:gallery, user: user)
      gallery2 = create(:gallery, user: user)
      char = create(:character, user: user)
      char.update!(galleries: [gallery1, gallery2])
      expect(char.character_gallery_for(gallery1.id).section_order).to eq(0)
      expect(char.character_gallery_for(gallery2.id).section_order).to eq(1)
    end

    it "updates order when removing galleries" do
      user = create(:user)
      gallery1 = create(:gallery, user: user)
      gallery2 = create(:gallery, user: user)
      gallery3 = create(:gallery, user: user)
      char = create(:character, user: user, galleries: [gallery1, gallery2, gallery3])
      char.update!(galleries: [gallery1, gallery3])
      expect(char.character_gallery_for(gallery1.id).section_order).to eq(0)
      expect(char.character_gallery_for(gallery3.id).section_order).to eq(1)
      expect(char.character_gallery_for(gallery2.id)).to be_nil
      # make sure it didn't destroy the removed gallery
      expect(Gallery.find_by(id: gallery2.id)).to eq(gallery2)
    end
  end

  it "orders icons by default" do
    user = create(:user)
    char = create(:character, user: user)
    gallery1 = create(:gallery, user: user)
    gallery2 = create(:gallery, user: user)
    char.update!(galleries: [gallery1, gallery2])
    icon2 = create(:icon, user: user, keyword: 'b', galleries: [gallery1])
    icon3 = create(:icon, user: user, keyword: 'c', galleries: [gallery2, gallery1])
    icon4 = create(:icon, user: user, keyword: 'd', galleries: [gallery1, gallery2])
    icon1 = create(:icon, user: user, keyword: 'a', galleries: [gallery2])
    expect(char.icons).to eq([icon1, icon2, icon3, icon4])
  end
end
