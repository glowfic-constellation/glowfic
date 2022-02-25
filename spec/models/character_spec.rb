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

  describe "#ungrouped_gallery_ids=" do
    it "adds unattached galleries" do
      user = create(:user)
      character = create(:character, user: user)
      gallery = create(:gallery, user: user)

      expect(character.gallery_ids).to eq([])
      expect(character.ungrouped_gallery_ids).to eq([])
      character.ungrouped_gallery_ids = [gallery.id]
      character.save!

      character.reload
      expect(character.characters_galleries.map(&:added_by_group?)).to match_array([false])
      expect(character.gallery_ids).to match_array([gallery.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery.id])
    end

    it "sets already-attached galleries to not be added_by_group" do
      # does not add a new attachment
      user = create(:user)
      group = create(:gallery_group)
      character = create(:character, gallery_groups: [group], user: user)
      gallery = create(:gallery, gallery_groups: [group], user: user)

      character.reload
      expect(character.gallery_ids).to match_array([gallery.id])
      expect(character.ungrouped_gallery_ids).to match_array([])

      character.ungrouped_gallery_ids = [gallery.id]
      character.save!
      character.reload

      expect(character.gallery_ids).to match_array([gallery.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery.id])
      expect(character.characters_galleries.map(&:added_by_group)).to match_array([false])
    end

    it "removes associated galleries when not present only if not also present in groups, otherwise sets flag" do
      # does not remove gallery_manual when not told to
      # sets flag on gallery_both to be added_by_group
      # does not remove gallery_auto despite not being present
      user = create(:user)
      group = create(:gallery_group)
      character = create(:character, gallery_groups: [group], user: user)
      gallery_manual = create(:gallery, user: user)
      gallery_both = create(:gallery, gallery_groups: [group], user: user)
      gallery_automatic = create(:gallery, gallery_groups: [group], user: user)

      CharactersGallery.create!(character: character, gallery: gallery_manual)
      character.characters_galleries.where(gallery_id: gallery_both.id).update_all(added_by_group: false) # rubocop:disable Rails/SkipsModelValidations

      character.reload
      expect(character.gallery_ids).to match_array([gallery_manual.id, gallery_both.id, gallery_automatic.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery_manual.id, gallery_both.id])

      character.ungrouped_gallery_ids = [gallery_manual.id]
      character.save!

      character.reload
      expect(character.gallery_ids).to match_array([gallery_manual.id, gallery_both.id, gallery_automatic.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery_manual.id])
      expect(character.characters_galleries.find_by(gallery_id: gallery_both.id)).to be_added_by_group
    end

    it "deletes manually-added galleries when not present" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      character = create(:character, user: user, galleries: [gallery])

      character.reload
      expect(character.gallery_ids).to eq([gallery.id])
      expect(character.ungrouped_gallery_ids).to eq([gallery.id])
      character.ungrouped_gallery_ids = []
      character.save!

      character.reload
      expect(character.gallery_ids).to eq([])
    end

    it "does nothing if unchanged" do
      # does not remove or change the status of any of: gallery_manual, gallery_both, gallery_auto
      user = create(:user)
      group = create(:gallery_group)
      character = create(:character, gallery_groups: [group], user: user)
      gallery_manual = create(:gallery, user: user)
      gallery_both = create(:gallery, gallery_groups: [group], user: user)
      gallery_automatic = create(:gallery, gallery_groups: [group], user: user)

      CharactersGallery.create!(character: character, gallery: gallery_manual)
      character.characters_galleries.where(gallery_id: gallery_both.id).update_all(added_by_group: false) # rubocop:disable Rails/SkipsModelValidations

      character.reload
      expect(character.gallery_ids).to match_array([gallery_manual.id, gallery_both.id, gallery_automatic.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery_manual.id, gallery_both.id])

      character.ungrouped_gallery_ids = [gallery_manual.id, gallery_both.id]
      character.save!

      character.reload
      expect(character.gallery_ids).to match_array([gallery_manual.id, gallery_both.id, gallery_automatic.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery_manual.id, gallery_both.id])
    end

    ['before', 'after'].each do |time|
      context "combined #{time} gallery_group_ids" do
        def process_changes(obj, gallery_group_ids, ungrouped_gallery_ids, time)
          if time == 'before'
            obj.ungrouped_gallery_ids = ungrouped_gallery_ids
            obj.gallery_group_ids = gallery_group_ids
          else
            obj.gallery_group_ids = gallery_group_ids
            obj.ungrouped_gallery_ids = ungrouped_gallery_ids
          end
        end

        it "supports adding a gallery at the same time as removing its group" do
          user = create(:user)
          group = create(:gallery_group)
          gallery = create(:gallery, user: user, gallery_groups: [group])
          character = create(:character, user: user, gallery_groups: [group])
          expect(character.reload.galleries).to match_array([gallery])

          process_changes(character, [], [gallery.id], time)
          character.save!

          character.reload
          expect(character.galleries).to match_array([gallery])
          expect(character.ungrouped_gallery_ids).to match_array([gallery.id])
          expect(character.gallery_groups).to match_array([])
        end

        it "supports adding a gallery at the same time as swapping its group" do
          user = create(:user)
          group1 = create(:gallery_group)
          group2 = create(:gallery_group)
          gallery = create(:gallery, user: user, gallery_groups: [group1, group2])
          character = create(:character, user: user, gallery_groups: [group1])
          expect(character.reload.galleries).to match_array([gallery])

          process_changes(character, [group2.id], [gallery.id], time)
          character.save!

          character.reload
          expect(character.galleries).to match_array([gallery])
          expect(character.ungrouped_gallery_ids).to match_array([gallery.id])
          expect(character.gallery_groups).to match_array([group2])
        end

        it "keeps a gallery when removing at the same time as adding its group" do
          user = create(:user)
          group = create(:gallery_group)
          gallery = create(:gallery, user: user, gallery_groups: [group])
          character = create(:character, user: user, galleries: [gallery])
          expect(character.reload.galleries).to match_array([gallery])

          process_changes(character, [group.id], [], time)
          character.save!

          character.reload
          expect(character.galleries).to match_array([gallery])
          expect(character.ungrouped_gallery_ids).to match_array([])
          expect(character.gallery_groups).to match_array([group])
        end

        it "keeps a gallery when removing at the same time as swapping its group" do
          user = create(:user)
          group1 = create(:gallery_group)
          group2 = create(:gallery_group)
          gallery = create(:gallery, user: user, gallery_groups: [group1, group2])
          character = create(:character, user: user, galleries: [gallery], gallery_groups: [group1])
          expect(character.reload.galleries).to match_array([gallery])

          process_changes(character, [group2.id], [], time)
          character.save!

          character.reload
          expect(character.galleries).to match_array([gallery])
          expect(character.ungrouped_gallery_ids).to match_array([])
          expect(character.gallery_groups).to match_array([group2])
        end
      end
    end
  end

  describe "audits" do
    before(:each) do
      Character.auditing_enabled = true
      expect(Audited::Audit.count).to eq(0) # rubocop:disable RSpec/ExpectInHook
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

  describe "#selector_name" do
    let(:character) { create(:character) }
    let(:screenname) { 'test_screename' }
    let(:nickname) { 'test nickname' }

    it "works with only name" do
      expect(character.selector_name).to eq(character.name)
    end

    it "works with all names" do
      character.update!(screenname: screenname, nickname: nickname)
      expect(character.selector_name).to eq("#{character.name} | #{nickname} | #{screenname}")
    end

    context "with include_settings" do
      let(:settings) { create_list(:setting, 2) }

      it "works with no settings" do
        expect(character.selector_name(include_settings: true)).to eq(character.name)
      end

      it "works with one setting" do
        character.update!(settings: [settings[0]])
        expect(character.selector_name(include_settings: true)).to eq("#{character.name} | #{settings[0].name}")
      end

      it "works with multiple settings" do
        character.update!(settings: settings)
        expect(character.selector_name(include_settings: true)).to eq("#{character.name} | #{settings[0].name} & #{settings[1].name}")
      end

      it "works with settings and names" do
        character.update!(settings: settings, screenname: screenname, nickname: nickname)
        string = "#{character.name} | #{nickname} | #{screenname} | #{settings[0].name} & #{settings[1].name}"
        expect(character.selector_name(include_settings: true)).to eq(string)
      end
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
