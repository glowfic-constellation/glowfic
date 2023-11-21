RSpec.describe Tag do
  describe "#merge_with" do
    it "takes the correct actions for post tags" do
      good_tag = create(:label)
      bad_tag = create(:label)

      # TODO handle properly with nested attributes
      create_list(:post, 3, label_ids: [good_tag.id], setting_ids: [], content_warning_ids: [])
      create_list(:post, 2, label_ids: [bad_tag.id], setting_ids: [], content_warning_ids: [])

      expect(good_tag.posts.count).to eq(3)
      expect(bad_tag.posts.count).to eq(2)

      good_tag.merge_with(bad_tag)

      expect(Tag.find_by(id: bad_tag.id)).to be_nil
      expect(bad_tag.posts.count).to eq(0)
      expect(good_tag.posts.count).to eq(5)
    end

    it "takes the correct actions for user tags" do
      good_tag = create(:content_warning)
      bad_tag = create(:content_warning)

      create_list(:user, 3, content_warning_ids: [good_tag.id])
      create_list(:user, 2, content_warning_ids: [bad_tag.id])

      expect(good_tag.users.count).to eq(3)
      expect(bad_tag.users.count).to eq(2)

      good_tag.merge_with(bad_tag)

      expect(ContentWarning.find_by(id: bad_tag.id)).to be_nil
      expect(bad_tag.users.count).to eq(0)
      expect(good_tag.users.count).to eq(5)
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

  describe "#user_count" do
    it "works" do
      tag1 = create(:content_warning)

      tag2 = create(:content_warning)
      user1 = create(:user)
      user1.update!(content_warning_ids: [tag2.id])

      tag3 = create(:content_warning)
      user2 = create(:user)
      user2.update!(content_warning_ids: [tag3.id])
      user3 = create(:user)
      user3.update!(content_warning_ids: [tag3.id])

      tags = [tag1, tag2, tag3]
      fetched = ContentWarning.where(id: tags.map(&:id)).ordered_by_id
      expect(fetched).to eq(tags)
      expect(fetched.map(&:user_count)).to eq([0, 1, 2])
    end
  end

  describe "#post_count" do
    it "works" do
      tag1 = create(:label)
      tag2 = create(:label)
      create(:post, labels: [tag2])
      tag3 = create(:label)
      create_list(:post, 2, labels: [tag3])
      tags = [tag1, tag2, tag3]
      fetched = Label.where(id: tags.map(&:id)).ordered_by_id
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

    it "works with with_character_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).select(:id).ordered_by_id.with_character_counts
      expect(fetched).to eq(tags)
      expect(fetched.map { |x| x[:character_count] }).to eq([0, 1, 2])
    end

    it "works without with_character_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).ordered_by_id
      expect(fetched).to eq(tags)
      expect(fetched.map(&:character_count)).to eq([0, 1, 2])
    end
  end
end
