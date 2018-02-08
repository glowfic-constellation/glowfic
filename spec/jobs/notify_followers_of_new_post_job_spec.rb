require "spec_helper"

RSpec.describe NotifyFollowersOfNewPostJob do
  before(:each) { ResqueSpec.reset! }

  it "does nothing with invalid post id" do
    expect(Favorite).not_to receive(:where)
    user = create(:user)
    NotifyFollowersOfNewPostJob.perform_now(-1, user.id)
  end

  it "does nothing with invalid user id" do
    expect(Favorite).not_to receive(:where)
    post = create(:post)
    NotifyFollowersOfNewPostJob.perform_now(post.id, -1)
  end

  context "on new posts" do
    it "does not send twice if the user has favorited both the poster and the continuity" do
      board = create(:board)
      author = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: board)
      create(:favorite, user: notified, favorite: author)
      post = create(:post, user: author, board: board)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id)
      }.to change { Message.count }.by(1)
    end

    it "sends the right messages based on favorite type" do
      board = create(:board)
      author = create(:user)
      board_notified = create(:user)
      author_notified = create(:user)
      expected = create(:user)
      create(:favorite, user: board_notified, favorite: board)
      create(:favorite, user: author_notified, favorite: author)
      post = create(:post, user: author, board: board, unjoined_authors: [expected])
      expect { NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id) }.to change { Message.count }.by(2)
      board_msg = Message.where(recipient: board_notified).last
      author_msg = Message.where(recipient: author_notified).last
      expect(board_msg.message).to include("in the #{board.name} continuity")
      expect(author_msg.message).not_to include("in the #{board.name} continuity")
      expect(board_msg.subject).to eq("New post by #{author.username}")
      expect(author_msg.message).to include(" with #{expected.username}")
    end

    it "does not send unless visible" do
      author = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)
      post = create(:post, user: author, privacy: Concealable::PRIVATE)
      expect { NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id) }.not_to change { Message.count }
    end

    it "does not send if reader has config disabled" do
      author = create(:user)
      notified = create(:user, favorite_notifications: false)
      create(:favorite, user: notified, favorite: author)
      post = create(:post, user: author)
      expect { NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id) }.not_to change { Message.count }
    end

    it "does not send to the poster" do
      board = create(:board)
      author = create(:user)
      create(:favorite, user: author, favorite: board)
      post = create(:post, user: author, board: board)
      expect { NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id) }.not_to change { Message.count }
    end
  end

  context "on joined posts" do
    it "does not send twice if the user has favorited both the poster and the replier" do
      author = create(:user)
      replier = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)
      create(:favorite, user: notified, favorite: replier)

      post = create(:post, user: author)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id)
      }.to change { Message.count }.by(1)

      reply = create(:reply, post: post, user: replier)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, reply.user_id)
      }.not_to change { Message.count }
    end

    it "does not send twice if the poster changes their username" do
      author = create(:user)
      replier = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)
      create(:favorite, user: notified, favorite: replier)

      post = create(:post, user: author)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id)
      }.to change { Message.count }.by(1)

      author.update_attributes(username: author.username + 'new')
      reply = create(:reply, post: post, user: replier)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, reply.user_id)
      }.not_to change { Message.count }
    end

    it "does not send twice if the post subject changes" do
      author = create(:user)
      replier = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)
      create(:favorite, user: notified, favorite: replier)

      post = create(:post, user: author)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id)
      }.to change { Message.count }.by(1)

      post.update_attributes(subject: post.subject + 'new')
      reply = create(:reply, post: post, user: replier)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, reply.user_id)
      }.not_to change { Message.count }
    end

    it "sends twice for different posts" do
      author = create(:user)
      replier = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)
      create(:favorite, user: notified, favorite: replier)

      post = create(:post, user: author)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id)
      }.to change { Message.count }.by(1)

      not_favorited_post = create(:post)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(not_favorited_post.id, not_favorited_post.user_id)
      }.not_to change { Message.count }

      reply = create(:reply, post: not_favorited_post, user: replier)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(not_favorited_post.id, reply.user_id)
      }.to change { Message.count }.by(1)
    end

    it "sends the right message" do
      author = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)

      post = create(:post)
      reply = create(:reply, post: post, user: author)
      expect {
        NotifyFollowersOfNewPostJob.perform_now(post.id, reply.user_id)
      }.to change { Message.count }.by(1)

      message = Message.last
      expect(message.subject).to eq("#{author.username} has joined a new thread")
      expect(message.message).to include(post.subject)
      expect(message.message).to include("with #{post.user.username}")
    end

    it "does not send unless visible" do
      author = create(:user)
      notified = create(:user)
      create(:favorite, user: notified, favorite: author)
      post = create(:post, privacy: Concealable::ACCESS_LIST, viewers: [author])
      reply = create(:reply, post: post, user: author)
      expect { NotifyFollowersOfNewPostJob.perform_now(post.id, author.id) }.not_to change { Message.count }
    end

    it "does not send if reader has config disabled" do
      author = create(:user)
      notified = create(:user, favorite_notifications: false)
      create(:favorite, user: notified, favorite: author)
      post = create(:post)
      reply = create(:reply, post: post, user: author)
      expect { NotifyFollowersOfNewPostJob.perform_now(post.id, author.id) }.not_to change { Message.count }
    end

    it "does not send to the poster" do
      author = create(:user)
      favorite = create(:user)
      create(:favorite, user: author, favorite: favorite)
      post = create(:post, user: author)
      reply = create(:reply, post: post, user: favorite)
      expect { NotifyFollowersOfNewPostJob.perform_now(post.id, favorite.id) }.not_to change { Message.count }
    end
  end
end
