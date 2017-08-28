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
