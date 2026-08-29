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

    it "collapses a spoiler tagging for a logged out viewer" do
      tagging = PostTag.create!(post: post, tag: tag, spoiler: true)
      expect(tagging.expanded_for?(nil)).to eq(false)
    end

    it "always expands for the post author" do
      tagging = PostTag.create!(post: post, tag: tag, spoiler: true)
      expect(tagging.expanded_for?(author)).to eq(true)
    end

    it "collapses for an ordinary reader regardless of how far they have read" do
      replies = create_list(:reply, 3, post: post, user: author)
      tagging = PostTag.create!(post: post, tag: tag, spoiler: true, reveal_after_reply_order: 1)
      reader = create(:user)
      post.mark_read(reader, at_time: replies.last.created_at)

      expect(tagging.expanded_for?(reader)).to eq(false)
    end

    it "expands for a reader who has opted in" do
      tagging = PostTag.create!(post: post, tag: tag, spoiler: true)
      reader = create(:user, reveal_spoiler_tags: true)
      expect(tagging.expanded_for?(reader)).to eq(true)
    end
  end

  describe "content warnings" do
    it "cannot be spoilered" do
      warning = create(:content_warning)
      tagging = PostTag.new(post: post, tag: warning, spoiler: true)
      expect(tagging).not_to be_valid
      expect(tagging.errors.full_messages.join).to include("content warning")
    end

    it "can carry a from-reply note without being a spoiler" do
      warning = create(:content_warning)
      expect(PostTag.new(post: post, tag: warning, reveal_after_reply_order: 3)).to be_valid
    end
  end

  describe "post-level helpers" do
    it "splits taggings by type and counts the spoilered ones" do
      label = create(:label)
      setting = create(:setting)
      warning = create(:content_warning)
      PostTag.create!(post: post, tag: label)
      PostTag.create!(post: post, tag: setting, spoiler: true, reveal_after_reply_order: 3)
      PostTag.create!(post: post, tag: warning)

      expect(post.displayable_tags(Label)).to eq([label])
      expect(post.displayable_tags(ContentWarning)).to eq([warning])
      expect(post.displayable_tags(Setting)).to eq([setting])
      expect(post.spoiler_post_tag_count).to eq(1)
    end

    it "includes spoilered taggings in the displayable set, collapsed by the view" do
      PostTag.create!(post: post, tag: tag, spoiler: true)
      expect(post.displayable_tags(Label)).to eq([tag])
    end
  end

  describe "reverse lookup" do
    it "excludes spoilered taggings" do
      visible = PostTag.create!(post: post, tag: tag)
      other_post = create(:post)
      PostTag.create!(post: other_post, tag: tag, spoiler: true)

      expect(PostTag.for_reverse_lookup.where(tag_id: tag.id)).to eq([visible])
    end

    it "omits a spoilered post from the tag's post listing" do
      listed = create(:post)
      PostTag.create!(post: listed, tag: tag)
      hidden = create(:post)
      PostTag.create!(post: hidden, tag: tag, spoiler: true)

      expect(tag.posts).to include(hidden)
      expect(tag.unspoilered_posts).to eq([listed])
    end
  end
end
