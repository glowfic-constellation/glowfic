RSpec.describe PostTag do
  let(:author) { create(:user) }
  let(:post) { create(:post, user: author) }
  let(:tag) { create(:label) }

  describe "#expanded_for?" do
    it "expands a non-spoiler tagging for anyone, including logged out" do
      tagging = PostTag.create!(post: post, tag: tag)
      expect(tagging.expanded_for?(nil)).to eq(true)
      expect(tagging.expanded_for?(create(:user))).to eq(true)
    end

    it "collapses a spoiler tagging for readers" do
      tagging = PostTag.create!(post: post, tag: tag, spoiler: true)
      expect(tagging.expanded_for?(nil)).to eq(false)
      expect(tagging.expanded_for?(create(:user))).to eq(false)
    end

    it "expands a spoiler tagging for the post author and mods" do
      tagging = PostTag.create!(post: post, tag: tag, spoiler: true)
      expect(tagging.expanded_for?(author)).to eq(true)
      expect(tagging.expanded_for?(create(:mod_user))).to eq(true)
    end

    it "expands a spoiler tagging for a reader who has opted in" do
      tagging = PostTag.create!(post: post, tag: tag, spoiler: true)
      expect(tagging.expanded_for?(create(:user, reveal_spoiler_tags: true))).to eq(true)
    end
  end

  describe "validations" do
    it "does not allow a content warning to be spoilered" do
      tagging = PostTag.new(post: post, tag: create(:content_warning), spoiler: true)
      expect(tagging).not_to be_valid
      expect(tagging.errors.full_messages.join).to include("content warning")
    end

    it "allows a content warning to note the reply it applies from" do
      expect(PostTag.new(post: post, tag: create(:content_warning), applies_from_reply_order: 3)).to be_valid
    end
  end
end
