RSpec.describe Gallery do
  it "adds icons if it saves successfully", :aggregate_failures do
    user = create(:user)
    icon = create(:icon, user: user)

    gallery = build(:gallery, user: user)
    gallery.icon_ids = [icon.id]

    expect(gallery).to be_valid
    expect(gallery.save).to eq(true)
    expect(icon.reload.has_gallery).to eq(true)
  end

  it "only adds icons if it saves successfully", :aggregate_failures do
    user = create(:user)
    icon = create(:icon, user: user)

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

  describe "#gallery_groups_data" do
    it "works without with_gallery_groups scope", :aggregate_failures do
      group = create(:gallery_group)
      gallery = create(:gallery, gallery_groups: [group])
      galleries = Gallery.where(id: gallery.id).select(:id)
      expect(galleries).to eq([gallery])
      expect(galleries.first.gallery_groups_data).to match_array([group])
    end

    context "with scope" do
      it "works for galleries without gallery groups", :aggregate_failures do
        gallery1 = create(:gallery)
        gallery2 = create(:gallery)
        galleries = Gallery.where(id: [gallery1.id, gallery2.id]).select(:id).with_gallery_groups.ordered_by_id
        expect(galleries).to eq([gallery1, gallery2])
        expect(galleries.map(&:gallery_groups_data)).to eq([[], []])
      end

      it "works for galleries with same gallery group", :aggregate_failures do
        group = create(:gallery_group)
        gallery1 = create(:gallery, gallery_groups: [group])
        gallery2 = create(:gallery, gallery_groups: [group])
        galleries = Gallery.where(id: [gallery1.id, gallery2.id]).select(:id).with_gallery_groups.ordered_by_id
        expect(galleries).to eq([gallery1, gallery2])
        groups = galleries.map(&:gallery_groups_data)
        expect(groups.first.map(&:id)).to eq([group.id])
        expect(groups.first.map(&:name)).to eq([group.name])
        expect(groups.last.map(&:id)).to eq([group.id])
        expect(groups.last.map(&:name)).to eq([group.name])
      end

      it "works for galleries with different gallery groups", :aggregate_failures do
        group1 = create(:gallery_group)
        group2 = create(:gallery_group)
        gallery1 = create(:gallery, gallery_groups: [group1])
        gallery2 = create(:gallery, gallery_groups: [group2])
        galleries = Gallery.where(id: [gallery1.id, gallery2.id]).select(:id).with_gallery_groups.ordered_by_id
        expect(galleries).to eq([gallery1, gallery2])
        groups = galleries.map(&:gallery_groups_data)
        expect(groups.first.map(&:id)).to eq([group1.id])
        expect(groups.first.map(&:name)).to eq([group1.name])
        expect(groups.last.map(&:id)).to eq([group2.id])
        expect(groups.last.map(&:name)).to eq([group2.name])
      end

      it "works for galleries with multiple gallery groups", :aggregate_failures do
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
