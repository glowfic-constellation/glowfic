require "spec_helper"

RSpec.describe Reply::Saver do
  let(:user) { create(:user) }
  let(:reply_post) { create(:post) }
  let(:params) { ActionController::Parameters.new }

  describe "create" do
    let(:reply) { build(:reply, user: user) }

    it "allows you to reply to a post you created" do
      reply_post = create(:post, user: user)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)
      expect(Reply.count).to eq(0)

      params[:reply] = { post_id: reply_post.id, content: 'test content!'}
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      reply.reload
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content!')
    end

    it "allows you to reply to join a post you did not create" do
      expect(Reply.count).to eq(0)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)

      params[:reply] = { post_id: reply_post.id, content: 'test content again!' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      reply.reload
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content again!')
    end

    it "allows you to reply to a post you already joined" do
      reply_old = create(:reply, post: reply_post, user: user)
      reply_post.mark_read(user, reply_old.created_at + 1.second, true)
      expect(Reply.count).to eq(1)

      params[:reply] = { post_id: reply_post.id, content: 'test content the third!' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      expect(Reply.count).to eq(2)
      expect(Reply.ordered.last).not_to eq(reply_old)
      reply.reload
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content the third!')
    end

    it "allows you to reply to a closed post you already joined" do
      reply_old = create(:reply, post: reply_post, user: user)
      reply_post.mark_read(user, reply_old.created_at + 1.second, true)
      expect(Reply.count).to eq(1)
      reply_post.update(authors_locked: true)

      params[:reply] = { post_id: reply_post.id, content: 'test content the third!' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      expect(Reply.count).to eq(2)
      reply.reload
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content the third!')
    end

    it "allows replies from authors in a closed post" do
      other_user = create(:user)
      reply_post = create(:post, user: other_user, tagging_authors: [user, other_user], authors_locked: true)
      reply_post.mark_read(user)

      params[:reply] = { post_id: reply_post.id, content: 'test content!' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      expect(Reply.count).to eq(1)
    end

    it "allows replies from owner in a closed post" do
      other_user = create(:user)
      other_post = create(:post, user: user, tagging_authors: [user, other_user], authors_locked: true)
      other_post.mark_read(user)

      params[:reply] = { post_id: other_post.id, content: 'more test content!' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      expect(Reply.count).to eq(1)
    end

    it "adds authors correctly when a user replies to an open thread" do
      reply_post.mark_read(user)

      params[:reply] = { post_id: reply_post.id, content: 'test content!' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      Timecop.freeze(Time.zone.now) do
        saver.create
      end

      expect(Reply.count).to eq(1)
      expect(reply_post.tagging_authors).to match_array([user, reply_post.user])
      post_author = reply_post.tagging_post_authors.find_by(user: user)
      expect(post_author.user).to eq(user)
      expect(post_author.joined).to eq(true)
      expect(post_author.joined_at).to be_the_same_time_as(Reply.last.created_at)
      expect(post_author.can_owe).to eq(true)
    end

    it "handles multiple replies to an open thread correctly" do
      expect(reply_post.tagging_authors.count).to eq(1)
      old_reply = create(:reply, post: reply_post, user: user)
      reply_post.reload
      expect(reply_post.tagging_authors).to include(user)
      expect(reply_post.tagging_authors.count).to eq(2)
      expect(reply_post.joined_authors).to include(user)
      expect(reply_post.joined_authors.count).to eq(2)
      expect(Reply.count).to eq(1)
      reply_post.mark_read(user, old_reply.created_at + 1.second, true)

      params[:reply] = { post_id: reply_post.id, content: 'test content!' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      expect(Reply.count).to eq(2)
      expect(reply_post.tagging_authors).to match_array([user, reply_post.user])
    end

    it "sets reply_order correctly on the first reply" do
      reply_post = create(:post, user: user)
      reply_post.mark_read(user)
      searchable = 'searchable content'

      params[:reply] = { post_id: reply_post.id, content: searchable }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      reply.reload
      expect(reply.content).to eq(searchable)
      expect(reply.reply_order).to eq(0)
    end

    it "sets reply_order correctly with an existing reply" do
      reply_post = create(:post, user: user)
      create(:reply, post: reply_post)
      reply_post.mark_read(user)
      searchable = 'searchable content'

      params[:reply] = { post_id: reply_post.id, content: searchable }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      reply.reload
      expect(reply.content).to eq(searchable)
      expect(reply.reply_order).to eq(1)
    end

    it "sets reply_order correctly with multiple existing replies" do
      reply_post = create(:post, user: user)
      create(:reply, post: reply_post)
      create(:reply, post: reply_post)
      reply_post.mark_read(user)
      searchable = 'searchable content'

      params[:reply] = { post_id: reply_post.id, content: searchable }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.create

      reply.reload
      expect(reply.content).to eq(searchable)
      expect(reply.reply_order).to eq(2)
    end
  end

  describe "update" do
    # let(:reply) { create(:reply, post: reply_post, user: user) }
    # let(:params) { ActionController::Parameters.new({ id: reply.id }) }

    it "preserves reply_order" do
      reply_post = create(:post, user: user)
      create(:reply, post: reply_post)
      reply = create(:reply, post: reply_post, user: user)
      params[:id] = reply.id
      expect(reply.reply_order).to eq(1)
      expect(reply_post.replies.ordered.last).to eq(reply)
      create(:reply, post: reply_post)
      expect(reply_post.replies.ordered.last).not_to eq(reply)
      reply_post.mark_read(reply_post.user)

      params[:reply] = { content: 'new content' }
      saver = Reply::Saver.new(reply, user: user, params: params)
      saver.update

      expect(reply.reload.reply_order).to eq(1)
    end
  end
end
