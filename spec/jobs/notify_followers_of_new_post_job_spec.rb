require "spec_helper"

RSpec.describe NotifyFollowersOfNewPostJob do
  before(:each) { ResqueSpec.reset! }
  it "does nothing with invalid post id" do
    expect(Favorite).not_to receive(:where)
    NotifyFollowersOfNewPostJob.perform_now(-1)
  end

  it "does not send twice if the user has favorited both the poster and the continuity" do
    board = create(:board)
    author = create(:user)
    notified = create(:user)
    create(:favorite, user: notified, favorite: board)
    create(:favorite, user: notified, favorite: author)
    post = create(:post, user: author, board: board)
    expect { NotifyFollowersOfNewPostJob.perform_now(post.id) }.to change { Message.count }.by(1)
  end

  it "sends the right messages based on favorite type" do
    board = create(:board)
    author = create(:user)
    board_notified = create(:user)
    author_notified = create(:user)
    create(:favorite, user: board_notified, favorite: board)
    create(:favorite, user: author_notified, favorite: author)
    post = create(:post, user: author, board: board)
    expect { NotifyFollowersOfNewPostJob.perform_now(post.id) }.to change { Message.count }.by(2)
    board_msg = Message.where(recipient: board_notified).last
    author_msg = Message.where(recipient: author_notified).last
    expect(board_msg.message).to include("in the #{board.name} continuity")
    expect(author_msg.message).not_to include("in the #{board.name} continuity")
  end

  it "does not send unless visible" do
    author = create(:user)
    notified = create(:user)
    create(:favorite, user: notified, favorite: author)
    post = create(:post, user: author, privacy: Concealable::PRIVATE)
    expect { NotifyFollowersOfNewPostJob.perform_now(post.id) }.not_to change { Message.count }
  end

  it "does not send if reader has config disabled" do
    author = create(:user)
    notified = create(:user, favorite_notifications: false)
    create(:favorite, user: notified, favorite: author)
    post = create(:post, user: author)
    expect { NotifyFollowersOfNewPostJob.perform_now(post.id) }.not_to change { Message.count }
  end

  it "does not send to the poster" do
    board = create(:board)
    author = create(:user)
    create(:favorite, user: author, favorite: board)
    post = create(:post, user: author, board: board)
    expect { NotifyFollowersOfNewPostJob.perform_now(post.id) }.not_to change { Message.count }
  end
end
