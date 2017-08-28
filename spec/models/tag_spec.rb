require "spec_helper"

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
end
