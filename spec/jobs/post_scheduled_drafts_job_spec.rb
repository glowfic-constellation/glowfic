RSpec.describe PostScheduledDraftsJob do
  include ActiveJob::TestHelper

  before(:each) { clear_enqueued_jobs }

  it "posts drafts whose scheduled time has passed" do
    due = create(:reply_draft, scheduled_at: 2.days.from_now)
    pending = create(:reply_draft, scheduled_at: 10.days.from_now)
    due_post = due.post

    Timecop.travel(3.days.from_now) do
      expect { PostScheduledDraftsJob.perform_now }.to change { due_post.replies.count }.by(1)
      expect(ReplyDraft.draft_for(due_post.id, due.user_id)).to be_nil
      expect(pending.reload).to be_scheduled
    end
  end

  it "posts drafts due in the same tick in scheduled order, not creation order" do
    shared_post = create(:post)
    author_a = create(:user)
    author_b = create(:user)

    # author_b's draft is created FIRST (lower id) but scheduled LATER
    later = create(:reply_draft, post: shared_post, user: author_b, content: 'second', scheduled_at: 2.days.from_now + 1.hour)
    earlier = create(:reply_draft, post: shared_post, user: author_a, content: 'first', scheduled_at: 2.days.from_now)
    expect(later.id).to be < earlier.id

    Timecop.travel(3.days.from_now) { PostScheduledDraftsJob.perform_now }

    replies = shared_post.replies.ordered
    expect(replies.map(&:content)).to eq(['first', 'second'])
    expect(replies.map(&:reply_order)).to eq([0, 1])
  end

  it "leaves plain drafts untouched" do
    draft = create(:reply_draft)
    expect { PostScheduledDraftsJob.perform_now }.not_to change { Reply.count }
    expect(draft.reload).to be_persisted
  end

  it "does nothing when there is nothing due" do
    create(:reply_draft, scheduled_at: 10.days.from_now)
    expect { PostScheduledDraftsJob.perform_now }.not_to change { Reply.count }
  end

  it "unqueues a draft that can no longer be posted and notifies" do
    board = create(:board, authors_locked: true)
    reply_post = create(:post, board: board, user: board.creator)
    outsider = create(:user) # cannot write in the now-locked continuity
    draft = create(:reply_draft, post: reply_post, user: outsider, scheduled_at: 2.days.from_now)
    expect(PostScheduledDraftsJob).to receive(:notify_exception)

    Timecop.travel(3.days.from_now) do
      expect { PostScheduledDraftsJob.perform_now }.not_to change { Reply.count }
      expect(draft.reload.scheduled_at).to be_nil
    end
  end
end
