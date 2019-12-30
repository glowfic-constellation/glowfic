require "spec_helper"

RSpec.describe Tag do
  describe "#merge_with" do
    it "takes the correct actions" do
      skip
      good_tag = create(:label)
      bad_tag = create(:label)

      # TODO handle properly with nested attributes
      create(:post, label_ids: [good_tag.id], setting_ids: [], content_warning_ids: [])
      create(:post, label_ids: [good_tag.id], setting_ids: [], content_warning_ids: [])
      create(:post, label_ids: [good_tag.id], setting_ids: [], content_warning_ids: [])
      create(:post, label_ids: [bad_tag.id], setting_ids: [], content_warning_ids: [])
      create(:post, label_ids: [bad_tag.id], setting_ids: [], content_warning_ids: [])

      expect(good_tag.posts.count).to eq(3)
      expect(bad_tag.posts.count).to eq(2)

      good_tag.merge_with(bad_tag)

      expect(Tag.find_by_id(bad_tag.id)).to be_nil
      expect(bad_tag.posts.count).to eq(0)
      expect(good_tag.posts.count).to eq(5)
    end
  end

  describe "validations" do
    it "requires unique name" do
      tag = create(:setting)
      new_tag = build(:setting, name: tag.name)
      expect(new_tag).not_to be_valid
    end

    it "requires unique case sensitive name" do
      tag = create(:setting, name: 'CASE')
      new_tag = build(:setting, name: tag.name.downcase)
      expect(new_tag).not_to be_valid
    end
  end

  describe "#post_count" do
    def create_tags
      tag1 = create(:setting)
      tag2 = create(:setting)
      create(:post, settings: [tag2])
      tag3 = create(:setting)
      create_list(:post, 2, settings: [tag3])
      [tag1, tag2, tag3]
    end

    it "works with with_item_counts scope" do
      tags = create_tags
      fetched = Setting.where(id: tags.map(&:id)).select(:id).ordered_by_id.with_item_counts
      expect(fetched).to eq(tags)
      expect(fetched.map(&:post_count)).to eq([0, 1, 2])
    end

    it "works without with_item_counts scope" do
      tags = create_tags
      fetched = Setting.where(id: tags.map(&:id)).ordered_by_id
      expect(fetched).to eq(tags)
      expect(fetched.map(&:post_count)).to eq([0, 1, 2])
    end
  end

  describe "#character_count" do
    def create_tags
      tag1 = create(:gallery_group)
      tag2 = create(:gallery_group)
      create(:character, gallery_groups: [tag2])
      tag3 = create(:gallery_group)
      create_list(:character, 2, gallery_groups: [tag3])
      [tag1, tag2, tag3]
    end

    it "works with with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).select(:id).ordered_by_id.with_item_counts
      expect(fetched).to eq(tags)
      expect(fetched.map(&:character_count)).to eq([0, 1, 2])
    end

    it "works without with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).ordered_by_id
      expect(fetched).to eq(tags)
      expect(fetched.map(&:character_count)).to eq([0, 1, 2])
    end
  end

  describe "#gallery_count" do
    def create_tags
      tag1 = create(:gallery_group)
      tag2 = create(:gallery_group)
      create(:gallery, gallery_groups: [tag2])
      tag3 = create(:gallery_group)
      create_list(:gallery, 2, gallery_groups: [tag3])
      [tag1, tag2, tag3]
    end

    it "works with with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).select(:id).ordered_by_id.with_item_counts
      expect(fetched).to eq(tags)
      expect(fetched.map(&:gallery_count)).to eq([0, 1, 2])
    end

    it "works without with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).ordered_by_id
      expect(fetched).to eq(tags)
      expect(fetched.map(&:gallery_count)).to eq([0, 1, 2])
    end
  end
end
