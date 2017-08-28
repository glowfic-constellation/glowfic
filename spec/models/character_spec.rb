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

  describe "#ungrouped_gallery_ids" do
    it "returns only galleries not added by groups" do
      user = create(:user)
      character = create(:character, user: user)
      gallery1 = create(:gallery, user: user)
      gallery2 = create(:gallery, user: user)

      CharactersGallery.create(character: character, gallery: gallery1)
      CharactersGallery.create(character: character, gallery: gallery2, added_by_group: true)

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

      CharactersGallery.create(character: character, gallery: gallery_manual)
      character.characters_galleries.where(gallery_id: gallery_both.id).update_all(added_by_group: false)

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

      CharactersGallery.create(character: character, gallery: gallery_manual)
      character.characters_galleries.where(gallery_id: gallery_both.id).update_all(added_by_group: false)

      character.reload
      expect(character.gallery_ids).to match_array([gallery_manual.id, gallery_both.id, gallery_automatic.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery_manual.id, gallery_both.id])

      character.ungrouped_gallery_ids = [gallery_manual.id, gallery_both.id]
      character.save!

      character.reload
      expect(character.gallery_ids).to match_array([gallery_manual.id, gallery_both.id, gallery_automatic.id])
      expect(character.ungrouped_gallery_ids).to match_array([gallery_manual.id, gallery_both.id])
    end
  end

  context "tags" do
    let(:taggable) { create(:character) }
    ['gallery_group'].each do |type|
      it "creates new #{type} tags if they don't exist" do
        taggable.send(type + '_ids=', ['_tag'])
        expect(taggable.send(type + 's').map(&:name)).to match_array(['tag'])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        expect(tags.map(&:name)).to match_array(['tag'])
        expect(tags.map(&:user)).to match_array([taggable.user])
      end

      it "uses extant tags with same name and type for #{type}" do
        tag = create(type)
        old_user = tag.user
        taggable.send(type + '_ids=', ['_' + tag.name])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
      end

      it "does not use extant tags of a different type with same name for #{type}" do
        name = "Example Tag"
        tag = create(:tag, type: 'NonexistentTag', name: name)
        taggable.send(type + '_ids=', ['_' + name])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        expect(tags.map(&:name)).to match_array([name])
        expect(tags.map(&:user)).to match_array([taggable.user])
        expect(tags).not_to include(tag)
      end

      it "uses extant #{type} tags by id" do
        tag = create(type)
        old_user = tag.user
        taggable.send(type + '_ids=', [tag.id.to_s])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
      end

      it "removes #{type} tags when not in list given" do
        tag = create(type)
        taggable.send(type + 's=', [tag])
        taggable.save
        taggable.reload
        expect(taggable.send(type + 's')).to match_array([tag])
        taggable.send(type + '_ids=', [])
        taggable.save
        taggable.reload
        expect(taggable.send(type + 's')).to eq([])
      end

      it "only adds #{type} tags once if given multiple times" do
        name = 'Example Tag'
        tag = create(type, name: name)
        old_user = tag.user
        taggable.send(type + '_ids=', ['_' + name, '_' + name, tag.id.to_s, tag.id.to_s])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
      end
    end
  end
end
