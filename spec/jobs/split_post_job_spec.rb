RSpec.describe SplitPostJob do
  include ActiveJob::TestHelper

  before(:each) { clear_enqueued_jobs }

  let(:title) { 'test subject' }

  describe "validations" do
    let!(:reply) { create(:reply) }

    it "requires valid subject" do
      expect {
        SplitPostJob.perform_now(reply.id, '')
      }.to raise_error(RuntimeError, 'Invalid subject')
    end

    it "requires valid reply id" do
      expect {
        SplitPostJob.perform_now(-1, title)
      }.to raise_error(RuntimeError, "Couldn't find reply")
    end

    it "requires existing reply" do
      reply.destroy!
      expect {
        SplitPostJob.perform_now(reply.id, title)
      }.to raise_error(RuntimeError, "Couldn't find reply")
    end

    it "works" do
      expect {
        SplitPostJob.perform_now(reply.id, title)
      }.to change { Post.count }.by(1)

      post = Post.last
      expect(post.subject).to eq(title)
      expect(post.replies.count).to eq(0)
      expect(post.content).to eq(reply.content)
      expect(Reply.find_by(id: reply.id)).not_to be_present
    end
  end

  it "works with many replies" do
    user = create(:user)
    coauthor = create(:user)
    cameo = create(:user)
    new_user = create(:user)

    post = create(:post, user: user, unjoined_authors: [coauthor])
    create(:reply, post: post, user: cameo)
    100.times { |i| create(:reply, post: post, user: i.even? ? user : coauthor) }
    create(:reply, post: post, user: new_user)

    previous = post.replies.find_by(reply_order: 49)
    reply = post.replies.find_by(reply_order: 50)
    next_reply = post.replies.find_by(reply_order: 51)
    last = post.replies.last

    expect {
      SplitPostJob.perform_now(reply.id, title)
    }.to change { Post.count }.by(1).and change { Reply.count }.by(-1)

    post.reload
    expect(post.replies.count).to eq(50)
    expect(post.replies.ordered.last).to eq(previous)
    expect(post.last_reply_id).to eq(previous.id)
    expect(post.last_user_id).to eq(previous.user_id)
    expect(post.tagged_at).to eq(previous.created_at)
    expect(post.authors).to match_array([user, coauthor, cameo])

    new_post = Post.last
    expect(new_post.subject).to eq(title)
    expect(new_post.replies.count).to eq(51)
    expect(new_post.content).to eq(reply.content)
    expect(new_post.user_id).to eq(reply.user.id)
    expect(new_post.authors).to match_array([user, coauthor, new_user])
    expect(new_post.last_reply_id).to eq(last.id)
    expect(new_post.last_user_id).to eq(last.user_id)
    expect(new_post.tagged_at).to eq(last.created_at)
    expect(new_post.replies.ordered.first).to eq(next_reply)
    expect(Reply.find_by(id: reply.id)).not_to be_present
  end

  it "copies original post's properties" do
    user = create(:user)
    board = create(:board)
    section = create(:board_section, board: board)
    setting = create(:setting, name: 'setting')
    warning = create(:content_warning, name: 'warning')
    label = create(:label, name: 'label')
    post = create(:post, user: user, board: board, section: section, setting_ids: [setting.id], content_warning_ids: [warning.id],
      label_ids: [label.id],)
    reply = create(:reply, post: post, user: user)

    expect {
      SplitPostJob.perform_now(reply.id, title)
    }.to change { Post.count }.by(1).and change { Reply.count }.by(-1)

    new_post = Post.last
    expect(new_post.board).to eq(board)
    expect(new_post.section).to eq(section)
    expect(new_post.setting_ids).to match_array([setting.id])
    expect(new_post.content_warning_ids).to match_array([warning.id])
    expect(new_post.label_ids).to match_array([label.id])
  end

  it "does not affect other posts" do
    user = create(:user)
    coauthor = create(:user)

    post = create(:post, user: user, unjoined_authors: [coauthor])
    10.times { |i| create(:reply, post: post, user: i.even? ? user : coauthor) }

    other_post = create(:post, num_replies: 10)

    expect {
      SplitPostJob.perform_now(post.replies.find_by(reply_order: 5).id, title)
    }.to change { Post.count }.by(1).and change { Reply.count }.by(-1)

    new_post = Post.last

    expect(post.replies.count).to eq(5)
    expect(new_post.replies.count).to eq(4)
    expect(other_post.replies.count).to eq(10)
  end
end
