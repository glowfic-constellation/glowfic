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

    it "is limited to one per user per post" do
      post = create(:post)
      user = create(:user)
      create(:reply_draft, user: user, post: post)
      draft = build(:reply_draft, post: post, user: user)
      expect(draft).not_to be_valid
      expect(draft.errors.messages).to eq({ post: ['has already been taken'] })
    end

    it "allows multiple drafts by different users on the same post" do
      post = create(:post)
      create(:reply_draft, post: post)
      draft = build(:reply_draft, post: post)
      expect(draft).to be_valid
    end

    it "allows multiple drafts by the same user on different posts" do
      user = create(:user)
      create(:reply_draft, user: user)
      draft = build(:reply_draft, user: user)
      expect(draft).to be_valid
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

    it "does not copy scheduled_at onto the reply" do
      draft = create(:reply_draft, scheduled_at: 2.days.from_now)
      reply = ReplyDraft.reply_from_draft(draft)
      expect(reply).to be_a(Reply)
      expect(reply.attributes).not_to have_key('scheduled_at')
    end
  end

  describe "scheduling" do
    describe "validations" do
      it "allows a future scheduled_at" do
        draft = build(:reply_draft, scheduled_at: 2.days.from_now)
        expect(draft).to be_valid
      end

      it "rejects a past scheduled_at" do
        draft = build(:reply_draft, scheduled_at: 2.days.ago)
        expect(draft).not_to be_valid
        expect(draft.errors[:scheduled_at]).to eq(["must be in the future"])
      end

      it "does not re-validate an unchanged elapsed schedule on later edits" do
        draft = create(:reply_draft, scheduled_at: 2.days.from_now)
        Timecop.travel(3.days.from_now) do
          draft.reload
          expect { draft.update!(content: 'edited') }.not_to raise_error
        end
      end
    end

    describe "#scheduled?" do
      it "is true when queued" do
        expect(build(:reply_draft, scheduled_at: 2.days.from_now)).to be_scheduled
      end

      it "is false for a plain draft" do
        expect(build(:reply_draft)).not_to be_scheduled
      end
    end

    describe ".due_for_posting" do
      it "only returns queued drafts whose time has come" do
        due = create(:reply_draft, scheduled_at: 2.days.from_now)
        pending = create(:reply_draft, scheduled_at: 10.days.from_now)
        plain = create(:reply_draft)

        Timecop.travel(3.days.from_now) do
          expect(ReplyDraft.due_for_posting).to match_array([due])
          expect(ReplyDraft.due_for_posting).not_to include(pending, plain)
        end
      end
    end

    describe "#post_as_reply!" do
      it "promotes the draft into a reply and removes the draft" do
        draft = create(:reply_draft, scheduled_at: 2.days.from_now)
        post = draft.post

        reply = nil
        expect {
          Timecop.travel(3.days.from_now) { reply = draft.post_as_reply! }
        }.to change { post.replies.count }.by(1).and change { ReplyDraft.count }.by(-1)

        expect(reply).to be_persisted
        expect(reply.content).to eq(draft.content)
        expect(reply.user_id).to eq(draft.user_id)
        expect(ReplyDraft.draft_for(post.id, draft.user_id)).to be_nil
      end
    end
  end
end
