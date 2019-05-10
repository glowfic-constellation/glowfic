require "spec_helper"

RSpec.describe ReplyDraft do
  describe "validations" do
    it "requires a post" do
      draft = build(:reply_draft, post: nil)
      expect(draft).not_to be_valid
    end

    it "requires a user" do
      draft = build(:reply_draft, user: nil)
      expect(draft).not_to be_valid
    end

    it "requires your icon" do
      draft = build(:reply_draft, icon: create(:icon))
      expect(draft).not_to be_valid
    end

    it "requires your character" do
      draft = build(:reply_draft, character: create(:character))
      expect(draft).not_to be_valid
    end

    it "works when valid" do
      user = create(:user)
      icon = create(:icon, user: user)
      character = create(:character, user: user)
      draft = build(:reply_draft, icon: icon, character: character, user: user)
      expect(draft).to be_valid
    end
  end

  describe ".draft_for" do
    it "does not find wrong post draft" do
      draft = create(:reply_draft)
      found = ReplyDraft.draft_for(draft.post_id + 1, draft.user_id)
      expect(found).to be_nil
    end

    it "does not find wrong user draft" do
      draft = create(:reply_draft)
      found = ReplyDraft.draft_for(draft.post_id, draft.user_id + 1)
      expect(found).to be_nil
    end

    it "finds correct draft" do
      draft = create(:reply_draft)
      found = ReplyDraft.draft_for(draft.post_id, draft.user_id)
      expect(found).to eq(draft)
    end
  end

  describe ".draft_reply_for" do
    it "handles no draft" do
      post = create(:post)
      found = ReplyDraft.draft_reply_for(post, post.user)
      expect(found).to be_nil
    end

    it "builds reply from draft" do
      draft = create(:reply_draft)
      found = ReplyDraft.draft_reply_for(draft.post, draft.user)
      expect(found).to be_a(Reply)
      expect(found).to be_a_new_record
      expect(found.content).to eq(draft.content)
    end
  end
end
