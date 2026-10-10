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
      expect(fetched.map { |x| x[:character_count] }).to eq([0, 1, 2]) # rubocop:disable Rails/Pluck
    end

    it "works without with_character_counts scope" do
      tags = create_tags
      fetched = GalleryGroup.where(id: tags.map(&:id)).ordered_by_id
      expect(fetched).to eq(tags)
      expect(fetched.map(&:character_count)).to eq([0, 1, 2])
    end
  end

  describe "#unspoilered_posts" do
    it "leaves out posts that carry the tag as a spoiler" do
      tag = create(:label)
      listed = create(:post, labels: [tag])
      hidden = create(:post)
      PostTag.create!(post: hidden, tag: tag, spoiler: true)

      expect(tag.posts).to include(hidden)
      expect(tag.unspoilered_posts).to eq([listed])
    end
  end

  describe "synonyms" do
    it "rejects a merger of a different type" do
      label = create(:label)
      label.merger = create(:setting, canonical: true)
      expect(label).not_to be_valid
      expect(label.errors.full_messages.join).to include("same type")
    end

    it "rejects a merger that is not itself canonical" do
      tag = create(:label)
      tag.merger = create(:label)
      expect(tag).not_to be_valid
      expect(tag.errors.full_messages.join).to include("canonical")
    end

    it "rejects a tag that is both canonical and a synonym" do
      tag = create(:label, canonical: true)
      tag.merger = create(:label, canonical: true)
      expect(tag).not_to be_valid
    end
  end

  describe "#merge_as_synonym" do
    let(:target) { create(:label, name: 'Bar Fight') }
    let(:loser) { create(:label, name: 'Barfight') }

    it "re-points taggings and keeps the loser as a synonym" do
      post = create(:post, labels: [loser])
      target.merge_as_synonym(loser)

      expect(post.reload.labels).to eq([target])
      expect(loser.reload.merger).to eq(target)
      expect(loser).to be_synonym
      expect(loser).not_to be_canonical
      expect(target.reload).to be_canonical
    end

    it "drops taggings that would collide" do
      post = create(:post, labels: [target, loser])
      expect { target.merge_as_synonym(loser) }.to change { PostTag.count }.by(-1)
      expect(post.reload.labels).to eq([target])
    end

    it "keeps synonym chains one level deep" do
      grand_loser = create(:label)
      loser.update!(canonical: true)
      grand_loser.update!(merger: loser)

      target.merge_as_synonym(loser)

      expect(grand_loser.reload.merger).to eq(target)
      expect(loser.reload.merger).to eq(target)
    end

    it "refuses to merge across types" do
      expect { create(:setting).merge_as_synonym(target) }.to raise_error(ArgumentError)
    end

    it "refuses to merge a tag into itself" do
      expect { target.merge_as_synonym(target) }.to raise_error(ArgumentError)
    end
  end

  describe ".awaiting_wrangling" do
    it "excludes synonyms, unwrangleable and canonical tags" do
      plain = create(:label)
      create(:label, unwrangleable: true)
      canonical = create(:label, canonical: true)
      create(:label).update!(merger: canonical)

      expect(Label.awaiting_wrangling).to eq([plain])
    end
  end

  describe "#wrangleable_by?" do
    let(:wrangler) { create(:wrangler_user) }

    it "allows a wrangler their assigned setting but not another" do
      assigned = create(:setting)
      create(:wrangling_assignment, user: wrangler, setting: assigned)

      expect(assigned.wrangleable_by?(wrangler)).to eq(true)
      expect(create(:setting).wrangleable_by?(wrangler)).to eq(false)
    end

    it "allows a wrangler a tag that shares a post with an assigned setting" do
      setting = create(:setting)
      label = create(:label)
      create(:post, settings: [setting], labels: [label])
      create(:wrangling_assignment, user: wrangler, setting: setting)

      expect(label.wrangleable_by?(wrangler)).to eq(true)
      expect(create(:label).wrangleable_by?(wrangler)).to eq(false)
    end

    it "does not extend to a setting that only shares a post with an assigned one" do
      setting = create(:setting)
      other = create(:setting)
      create(:post, settings: [setting, other])
      create(:wrangling_assignment, user: wrangler, setting: setting)

      expect(other.wrangleable_by?(wrangler)).to eq(false)
    end

    it "allows admins everything without assignments" do
      expect(create(:content_warning).wrangleable_by?(create(:admin_user))).to eq(true)
    end

    it "denies users and mods" do
      expect(create(:setting).wrangleable_by?(create(:user))).to eq(false)
      expect(create(:setting).wrangleable_by?(create(:mod_user))).to eq(false)
    end
  end
end
