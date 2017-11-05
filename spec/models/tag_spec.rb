require "spec_helper"
require "support/shared_examples_for_taggable"

RSpec.describe Tag do
  describe "#merge_with" do
    it "takes the correct actions" do
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
      tag = create(:label)
      new_tag = build(:label, name: tag.name)
      expect(new_tag).not_to be_valid
    end

    it "requires unique case sensitive name" do
      tag = create(:label, name: 'CASE')
      new_tag = build(:label, name: tag.name.downcase)
      expect(new_tag).not_to be_valid
    end
  end

  describe "#id_for_select" do
    it "uses ID if persisted" do
      tag = create(:label)
      expect(tag.id_for_select).to eq(tag.id)
    end

    it "uses name with prepended underscore otherwise" do
      tag = build(:label, name: 'tag')
      expect(tag.id_for_select).to eq('_tag')
    end
  end

  describe "#post_count" do
    def create_tags
      tag1 = create(:label)
      tag2 = create(:label)
      create(:post, labels: [tag2])
      tag3 = create(:label)
      2.times { create(:post, labels: [tag3]) }
      [tag1, tag2, tag3]
    end

    it "works with with_item_counts scope" do
      tags = create_tags
      fetched = Label.where(id: tags.map(&:id)).select(:id).order(:id).with_item_counts
      expect(fetched).to eq(tags)
      expect(fetched.map(&:post_count)).to eq([0, 1, 2])
    end

    it "works without with_item_counts scope" do
      tags = create_tags
      fetched = Label.where(id: tags.map(&:id)).order(:id)
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
      2.times { create(:character, gallery_groups: [tag3]) }
      [tag1, tag2, tag3]
    end

    it "works with with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).select(:id).order(:id).with_item_counts
      expect(fetched).to eq(tags)
      expect(fetched.map(&:character_count)).to eq([0, 1, 2])
    end

    it "works without with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).order(:id)
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
      2.times { create(:gallery, gallery_groups: [tag3]) }
      [tag1, tag2, tag3]
    end

    it "works with with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).select(:id).order(:id).with_item_counts
      expect(fetched).to eq(tags)
      expect(fetched.map(&:gallery_count)).to eq([0, 1, 2])
    end

    it "works without with_item_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).order(:id)
      expect(fetched).to eq(tags)
      expect(fetched.map(&:gallery_count)).to eq([0, 1, 2])
    end
  end
end

RSpec.describe Setting do
  # from Taggable concern
  context "tags" do
    it_behaves_like 'taggable', 'canon'
  end
end
