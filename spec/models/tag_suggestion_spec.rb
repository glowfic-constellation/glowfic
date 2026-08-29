RSpec.describe TagSuggestion do
  let(:author) { create(:user) }
  let(:reader) { create(:user) }
  let(:post) { create(:post, user: author) }
  let(:tag) { create(:label) }

  describe ".submit" do
    it "creates a pending suggestion and notifies the author" do
      record, outcome = TagSuggestion.submit(post: post, user: reader, tag: tag)

      expect(outcome).to eq(:created)
      expect(record).to be_pending
      expect(Notification.where(user: author, notification_type: :tag_suggested)).to be_present
    end

    it "accepts a proposed new tag name" do
      record, outcome = TagSuggestion.submit(post: post, user: reader, tag_type: 'Label', tag_name: 'Brand New')
      expect(outcome).to eq(:created)
      expect(record.tag_display_name).to eq('Brand New')
    end

    it "tells the suggester when the tag is already visibly applied" do
      PostTag.create!(post: post, tag: tag)
      record, outcome = TagSuggestion.submit(post: post, user: reader, tag: tag)

      expect(outcome).to eq(:already_visible)
      expect(record).to be_nil
    end

    context "when the collision is invisible to the suggester" do
      it "records an endorsement rather than revealing a hidden spoiler tagging" do
        create_list(:reply, 3, post: post, user: author)
        PostTag.create!(post: post, tag: tag, spoiler: true, reveal_after_reply_order: 3)

        record, outcome = TagSuggestion.submit(post: post, user: reader, tag: tag)

        expect(outcome).to eq(:endorsed)
        expect(record).to be_endorsed
        expect(record).not_to be_actionable
      end

      it "silently dedupes against a standing rejection rather than revealing it" do
        TagSuggestion.create!(post: post, user: create(:user), tag: tag, status: :rejected)

        record, outcome = TagSuggestion.submit(post: post, user: reader, tag: tag)

        expect(outcome).to eq(:silently_deduped)
        expect(record).to be_nil
      end

      it "silently dedupes against another reader's pending suggestion" do
        TagSuggestion.create!(post: post, user: create(:user), tag: tag)

        _record, outcome = TagSuggestion.submit(post: post, user: reader, tag: tag)

        expect(outcome).to eq(:silently_deduped)
      end

      it "blocks a rejected tag re-proposed by name rather than by id" do
        named = create(:label, name: 'Spoilery')
        TagSuggestion.create!(post: post, user: create(:user), tag: named, status: :rejected)

        _record, outcome = TagSuggestion.submit(post: post, user: reader, tag_type: 'Label', tag_name: 'spoilery')

        expect(outcome).to eq(:endorsed).or eq(:silently_deduped)
      end
    end
  end

  describe "validations" do
    it "rejects a suggestion naming both an existing tag and a new name" do
      record = TagSuggestion.new(post: post, user: reader, tag: tag, tag_type: 'Label', tag_name: 'x')
      expect(record).not_to be_valid
    end

    it "rejects a suggestion naming neither" do
      expect(TagSuggestion.new(post: post, user: reader)).not_to be_valid
    end

    it "refuses suggestions from the post's own author" do
      record = TagSuggestion.new(post: post, user: author, tag: tag)
      expect(record).not_to be_valid
      expect(record.errors.full_messages.join).to include("tag their own post directly")
    end

    it "refuses when the author has turned suggestions off" do
      post.update!(allow_tag_suggestions: false)
      expect(TagSuggestion.new(post: post, user: reader, tag: tag)).not_to be_valid
    end

    it "refuses a gallery group, which cannot be applied to a post" do
      group = create(:gallery_group)
      expect(TagSuggestion.new(post: post, user: reader, tag: group)).not_to be_valid
    end

    it "does not raise when endorsing on a post that stopped accepting suggestions" do
      create_list(:reply, 2, post: post, user: author)
      PostTag.create!(post: post, tag: tag, spoiler: true)
      post.update!(allow_tag_suggestions: false)

      expect {
        record, outcome = TagSuggestion.submit(post: post, user: reader, tag: tag)
        expect(outcome).to eq(:not_accepted)
        expect(record).to be_nil
      }.not_to raise_error
    end

    it "enforces a per-post pending cap" do
      described_class::MAX_PENDING_PER_POST.times do
        TagSuggestion.create!(post: post, user: create(:user), tag: create(:label))
      end
      expect(TagSuggestion.new(post: post, user: reader, tag: tag)).not_to be_valid
    end
  end

  describe "resolution" do
    it "accepting applies the tag to the post" do
      record = TagSuggestion.create!(post: post, user: reader, tag: tag)
      record.accept!(resolver: author)

      expect(post.reload.labels).to eq([tag])
      expect(record.reload).to be_accepted
    end

    it "accepting carries the suggested spoiler settings onto the tagging" do
      create_list(:reply, 3, post: post, user: author)
      record = TagSuggestion.create!(
        post: post, user: reader, tag: tag,
        spoiler: true, reveal_after_reply_order: 2,
      )
      record.accept!(resolver: author)

      tagging = PostTag.find_by(post: post, tag: tag)
      expect(tagging).to be_spoiler
      expect(tagging.reveal_after_reply_order).to eq(2)
    end

    it "accepting a proposed name creates the tag attributed to the suggester" do
      record = TagSuggestion.create!(post: post, user: reader, tag_type: 'Label', tag_name: 'Fresh')
      record.accept!(resolver: author)

      created = Label.find_by(name: 'Fresh')
      expect(created.user).to eq(reader)
      expect(post.reload.labels).to eq([created])
    end

    it "rejecting blocks the tag for everyone until allowed again" do
      record = TagSuggestion.create!(post: post, user: reader, tag: tag)
      record.reject!(resolver: author)

      _other, outcome = TagSuggestion.submit(post: post, user: create(:user), tag: tag)
      expect(outcome).to eq(:silently_deduped)

      record.allow_again!
      _retry, retry_outcome = TagSuggestion.submit(post: post, user: create(:user), tag: tag)
      expect(retry_outcome).to eq(:created)
    end
  end
end
