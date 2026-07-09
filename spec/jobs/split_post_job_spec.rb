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
      expect(post.replies.count).to eq(1)
      expect(post.content).to eq(reply.content)
      expect(post.editor_mode).to eq(reply.editor_mode)
      expect(reply.reload).to eq(post.written)
    end
  end

  describe "unread markers" do
    # splitting at replies[2] moves replies[2..4]; replies[1] becomes the old post's last reply
    let(:post) { create(:post) }
    let(:replies) { create_list(:reply, 5, post: post) }

    it "leaves users before the boundary alone" do
      before_boundary = create(:user)
      Post.find(post.id).mark_read(before_boundary, at_reply: replies[0])

      SplitPostJob.perform_now(replies[2].id, title)

      new_post = Post.last
      expect(post.views.find_by(user: before_boundary).last_read_reply).to eq(replies[0])
      expect(new_post.views.find_by(user: before_boundary)).to be_nil
      expect(Post.find(post.id).first_unread_for(before_boundary)).to eq(replies[1])
    end

    it "resurfaces the old post with no new replies for users at the boundary" do
      at_boundary = create(:user)
      Post.find(post.id).mark_read(at_boundary, at_reply: replies[1])

      SplitPostJob.perform_now(replies[2].id, title)

      new_post = Post.last
      view = post.views.find_by(user: at_boundary)
      expect(view.last_read_reply).to eq(replies[1])
      expect(view.read_at).to be < post.reload.tagged_at # flagged as if the last reply had been edited
      expect(Post.find(post.id).first_unread_for(at_boundary)).to be_nil # but with no new replies
      expect(new_post.views.find_by(user: at_boundary)).to be_nil # and the new post fully unread
    end

    it "migrates read state into the new post for users midway through the moved replies" do
      midway = create(:user)
      Post.find(post.id).mark_read(midway, at_reply: replies[3])

      SplitPostJob.perform_now(replies[2].id, title)

      new_post = Post.last
      old_view = post.views.find_by(user: midway)
      expect(old_view.last_read_reply).to eq(replies[1])
      expect(old_view.read_at).to be < post.reload.tagged_at
      expect(Post.find(post.id).first_unread_for(midway)).to be_nil

      new_view = new_post.views.find_by(user: midway)
      expect(new_view.last_read_reply).to eq(replies[3])
      expect(new_view.read_at).to be_the_same_time_as(old_view.read_at)
      expect(new_post.first_unread_for(midway)).to eq(replies[4])
    end

    it "resurfaces both posts with no new replies for fully caught up users" do
      caught_up = create(:user)
      Post.find(post.id).mark_read(caught_up, at_reply: replies[4])

      SplitPostJob.perform_now(replies[2].id, title)

      new_post = Post.last
      old_view = post.views.find_by(user: caught_up)
      expect(old_view.last_read_reply).to eq(replies[1])
      expect(old_view.read_at).to be < post.reload.tagged_at
      expect(Post.find(post.id).first_unread_for(caught_up)).to be_nil

      new_view = new_post.views.find_by(user: caught_up)
      expect(new_view.last_read_reply).to eq(replies[4])
      expect(new_view.read_at).to be < new_post.tagged_at
      expect(new_post.first_unread_for(caught_up)).to be_nil
    end

    it "carries hidden state into the new post" do
      user = create(:user)
      Post.find(post.id).mark_read(user, at_reply: replies.last)
      post.views.find_by(user: user).update!(ignored: true, warnings_hidden: true)

      SplitPostJob.perform_now(replies[2].id, title)

      new_view = Post.last.views.find_by(user: user)
      expect(new_view.ignored).to eq(true)
      expect(new_view.warnings_hidden).to eq(true)
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

    previous = post.replies.find_by(reply_order: 50)
    reply = post.replies.find_by(reply_order: 51)
    next_reply = post.replies.find_by(reply_order: 52)
    last = post.replies.last

    split_time = Time.zone.now
    expect {
      Timecop.freeze(split_time) { SplitPostJob.perform_now(reply.id, title) }
    }.to change { Post.count }.by(1).and not_change { Reply.count }

    post.reload
    expect(post.replies.count).to eq(51)
    expect(post.replies.ordered.last).to eq(previous)
    expect(post.last_reply_id).to eq(previous.id)
    expect(post.last_user_id).to eq(previous.user_id)
    expect(post.tagged_at).to be_the_same_time_as(split_time)
    expect(post.authors).to match_array([user, coauthor, cameo])

    new_post = Post.last
    expect(new_post.subject).to eq(title)
    expect(new_post.replies.count).to eq(52)
    expect(new_post.content).to eq(reply.content)
    expect(new_post.user_id).to eq(reply.user.id)
    expect(new_post.authors).to match_array([user, coauthor, new_user])
    expect(new_post.last_reply_id).to eq(last.id)
    expect(new_post.last_user_id).to eq(last.user_id)
    expect(new_post.tagged_at).to be_the_same_time_as(split_time)
    expect(new_post.replies.ordered.first).to eq(reply)
    expect(new_post.replies.ordered.second).to eq(next_reply)
    expect(reply.reload).to eq(new_post.written)
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
    }.to change { Post.count }.by(1).and not_change { Reply.count }

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
      SplitPostJob.perform_now(post.replies.find_by(reply_order: 6).id, title)
    }.to change { Post.count }.by(1).and not_change { Reply.count }

    new_post = Post.last

    expect(post.replies.count).to eq(6)
    expect(new_post.replies.count).to eq(5)
    expect(other_post.replies.count).to eq(11)
  end
end
