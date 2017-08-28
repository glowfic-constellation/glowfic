require "spec_helper"

RSpec.describe Gallery do
  it "adds icons if it saves successfully" do
    user = create(:user)
    icon = create(:icon, user: user)
    expect(icon.has_gallery).to eq(false)
    gallery = build(:gallery, user: user)
    gallery.icon_ids = [icon.id]
    expect(gallery).to be_valid
    expect(gallery.save).to be_true
    expect(icon.reload.has_gallery).to be_true
  end

  it "only adds icons if it saves successfully" do
    user = create(:user)
    icon = create(:icon, user: user)
    expect(icon.has_gallery).to eq(false)
    gallery = build(:gallery, user: user, name: nil)
    gallery.icon_ids = [icon.id]
    expect(gallery).not_to be_valid
    expect(gallery.save).to eq(false)
    expect(icon.reload.has_gallery).to eq(false)
  end

  it "returns icons in keyword order" do
    gallery = create(:gallery)
    gallery.icons << create(:icon, keyword: 'zzz', user: gallery.user)
    gallery.icons << create(:icon, keyword: 'yyy', user: gallery.user)
    gallery.icons << create(:icon, keyword: 'xxx', user: gallery.user)
    expect(gallery.icons.pluck(:keyword)).to eq(['xxx', 'yyy', 'zzz'])
  end

  context "tags" do
    let(:taggable) { create(:gallery) }
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
