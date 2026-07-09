RSpec.describe MergePostsJob do
  let(:user) { create(:user) }
  let(:source_post) { create(:post, user: user, authors_locked: true) }
  let(:target_post) { create(:post, user: user, authors_locked: true) }
  let(:source_replies) { create_list(:reply, 3, post: source_post, user: user) }
  let(:target_replies) { create_list(:reply, 4, post: target_post, user: user) }

  def merge_at(target_reply, privacy: 'public', setting_ids: [], content_warning_ids: [], label_ids: [])
    MergePostsJob.perform_now(source_post.id, target_reply.id, privacy, setting_ids, content_warning_ids, label_ids)
  end

  describe "validations" do
    it "requires existing source post" do
      expect {
        MergePostsJob.perform_now(-1, target_replies.first.id, 'public', [], [], [])
      }.to raise_error(RuntimeError, "Couldn't find source post")
    end

    it "requires existing target reply" do
      expect {
        MergePostsJob.perform_now(source_post.id, -1, 'public', [], [], [])
      }.to raise_error(RuntimeError, "Couldn't find target reply")
    end
  end

  it "splices the source's replies in after a mid-thread target reply" do
    source_replies
    target_replies

    merge_at(target_replies[1])

    expected = [target_post.written, target_replies[0], target_replies[1],
                source_post.written, *source_replies,
                target_replies[2], target_replies[3]]
    expect(target_post.replies.ordered).to eq(expected)
    expect(target_post.replies.ordered.map(&:reply_order)).to eq((0..8).to_a)
    expect(Reply.where(post_id: source_post.id)).to be_empty
  end

  it "splices the source's replies in right after the written" do
    source_replies
    target_replies

    merge_at(target_post.written)

    expected = [target_post.written, source_post.written, *source_replies, *target_replies]
    expect(target_post.replies.ordered).to eq(expected)
    expect(target_post.replies.ordered.map(&:reply_order)).to eq((0..8).to_a)
  end

  it "preserves reply ids and timestamps" do
    reply = source_replies.first
    old_created_at = reply.created_at
    old_updated_at = reply.updated_at

    merge_at(target_replies.last)

    reply.reload
    expect(reply.post_id).to eq(target_post.id)
    expect(reply.created_at).to be_the_same_time_as(old_created_at)
    expect(reply.updated_at).to be_the_same_time_as(old_updated_at)
  end

  it "moves bookmarks along with the replies" do
    moved = create(:bookmark, reply: source_replies.first, post: source_post, user: user)
    stays = create(:bookmark, reply: target_replies.first, post: target_post, user: user)

    merge_at(target_replies.last)

    expect(moved.reload.post_id).to eq(target_post.id)
    expect(stays.reload.post_id).to eq(target_post.id)
  end

  it "applies the chosen metadata" do
    setting = create(:setting)
    warning = create(:content_warning)
    label = create(:label)
    target_post.update!(settings: [create(:setting)])

    merge_at(target_replies.last, privacy: 'access_list', setting_ids: [setting.id], content_warning_ids: [warning.id], label_ids: [label.id])

    target_post.reload
    expect(target_post.privacy).to eq('access_list')
    expect(target_post.settings).to eq([setting])
    expect(target_post.content_warnings).to eq([warning])
    expect(target_post.labels).to eq([label])
  end

  it "updates the last reply cache when merging at the end" do
    source_replies
    target_replies

    merge_at(target_replies.last)

    target_post.reload
    expect(target_post.last_reply_id).to eq(source_replies.last.id)
    expect(target_post.last_user_id).to eq(source_replies.last.user_id)
  end

  it "keeps the last reply cache when merging mid-thread" do
    source_replies
    target_replies

    merge_at(target_replies[0])

    target_post.reload
    expect(target_post.last_reply_id).to eq(target_replies.last.id)
  end

  it "uses the newer tagged_at of the two posts" do
    Timecop.freeze(2.days.ago) { target_replies }
    source_replies

    source_tagged = source_post.reload.tagged_at
    merge_at(target_replies.last)

    expect(target_post.reload.tagged_at).to be_the_same_time_as(source_tagged)
  end

  it "keeps the target's tagged_at when it is newer" do
    Timecop.freeze(2.days.ago) { source_replies }
    target_replies

    target_tagged = target_post.reload.tagged_at
    merge_at(target_replies.last)

    expect(target_post.reload.tagged_at).to be_the_same_time_as(target_tagged)
  end

  it "regenerates the target's flat post" do
    source_replies
    target_replies
    $redis.del(GenerateFlatPostJob.lock_key(target_post.id)) # release the lock from the replies' creation
    expect {
      merge_at(target_replies.last)
    }.to enqueue_job(GenerateFlatPostJob).with(target_post.id)
  end
end
