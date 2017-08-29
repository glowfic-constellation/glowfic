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

  # from Taggable concern; duplicated between PostSpec, CharacterSpec, GallerySpec
  context "tags" do
    let(:taggable) { create(:gallery) }
    ['gallery_group'].each do |type|
      it "creates new #{type} tags if they don't exist" do
        taggable.send(type + '_ids=', ['_tag'])
        expect(taggable.send(type + 's').map(&:name)).to match_array(['tag'])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
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
        tag_ids = taggable.send(type + '_ids')
        expect(tags.map(&:name)).to match_array([name])
        expect(tags.map(&:user)).to match_array([taggable.user])
        expect(tags).not_to include(tag)
        expect(tag_ids).to match_array(tags.map(&:id))
      end

      it "uses extant #{type} tags by id" do
        tag = create(type)
        old_user = tag.user
        taggable.send(type + '_ids=', [tag.id.to_s])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
        expect(tag_ids).to match_array([tag.id])
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
        expect(taggable.send(type + '_ids')).to eq([])
      end

      it "only adds #{type} tags once if given multiple times" do
        name = 'Example Tag'
        tag = create(type, name: name)
        old_user = tag.user
        taggable.send(type + '_ids=', ['_' + name, '_' + name, tag.id.to_s, tag.id.to_s])
        taggable.save
        taggable.reload
        tags = taggable.send(type + 's')
        tag_ids = taggable.send(type + '_ids')
        expect(tags).to match_array([tag])
        expect(tags.map(&:user)).to match_array([old_user])
        expect(tag_ids).to match_array([tag.id])
      end
    end
  end

  describe "#gallery_groups_data" do
    it "works without with_gallery_groups scope" do
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group])
      galleries = Gallery.where(id: gallery.id).select(:id)
      expect(galleries).to eq([gallery])
      expect(galleries.first.gallery_groups_data).to match_array([group])
    end

    context "with scope" do
      it "works for galleries without gallery groups" do
        gallery1 = create(:gallery)
        gallery2 = create(:gallery)
        galleries = Gallery.where(id: [gallery1.id, gallery2.id]).select(:id).with_gallery_groups.order('id asc')
        expect(galleries).to eq([gallery1, gallery2])
        expect(galleries.map(&:gallery_groups_data)).to eq([[], []])
      end

      it "works for galleries with same gallery group" do
        group = create(:gallery_group)
        gallery1 = create(:gallery, gallery_groups: [group])
        gallery2 = create(:gallery, gallery_groups: [group])
        galleries = Gallery.where(id: [gallery1.id, gallery2.id]).select(:id).with_gallery_groups.order('id asc')
        expect(galleries).to eq([gallery1, gallery2])
        groups = galleries.map(&:gallery_groups_data)
        expect(groups.first.map(&:id)).to eq([group.id])
        expect(groups.first.map(&:name)).to eq([group.name])
        expect(groups.last.map(&:id)).to eq([group.id])
        expect(groups.last.map(&:name)).to eq([group.name])
      end

      it "works for galleries with different gallery groups" do
        group1 = create(:gallery_group)
        group2 = create(:gallery_group)
        gallery1 = create(:gallery, gallery_groups: [group1])
        gallery2 = create(:gallery, gallery_groups: [group2])
        galleries = Gallery.where(id: [gallery1.id, gallery2.id]).select(:id).with_gallery_groups.order('id asc')
        expect(galleries).to eq([gallery1, gallery2])
        groups = galleries.map(&:gallery_groups_data)
        expect(groups.first.map(&:id)).to eq([group1.id])
        expect(groups.first.map(&:name)).to eq([group1.name])
        expect(groups.last.map(&:id)).to eq([group2.id])
        expect(groups.last.map(&:name)).to eq([group2.name])
      end

      it "works for galleries with multiple gallery groups" do
        group1 = create(:gallery_group, name: 'Tag1')
        group2 = create(:gallery_group, name: 'Tag2')
        gallery = create(:gallery, name: 'Tag1', gallery_groups: [group1, group2])
        galleries = Gallery.where(id: [gallery.id]).select(:id).with_gallery_groups
        expect(galleries).to eq([gallery])
        groups = galleries.map(&:gallery_groups_data)
        expect(groups.first.map(&:id)).to eq([group1.id, group2.id])
        expect(groups.first.map(&:name)).to eq([group1.name, group2.name])
      end
    end
  end
end
