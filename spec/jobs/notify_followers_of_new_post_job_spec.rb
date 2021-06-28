RSpec.describe NotifyFollowersOfNewPostJob do
  include ActiveJob::TestHelper
  before(:each) { clear_enqueued_jobs }

  it "does nothing with invalid post id" do
    expect(Favorite).not_to receive(:where)
    user = create(:user)
    NotifyFollowersOfNewPostJob.perform_now(-1, user.id, 'new')
  end

  it "does nothing with invalid user id on join" do
    expect(Favorite).not_to receive(:where)
    post = create(:post)
    NotifyFollowersOfNewPostJob.perform_now(post.id, -1, 'join')
  end

  it "does nothing with invalid user id on access" do
    expect(Favorite).not_to receive(:where)
    post = create(:post)
    NotifyFollowersOfNewPostJob.perform_now(post.id, -1, 'access')
  end

  it "does nothing with invalid action" do
    expect(Favorite).not_to receive(:where)
    post = create(:post)
    NotifyFollowersOfNewPostJob.perform_now(post.id, post.user_id, '')
  end

  context "on new posts" do
    let(:author) { create(:user) }
    let(:coauthor) { create(:user) }
    let(:unjoined) { create(:user) }
    let(:notified) { create(:user) }
    let(:board) { create(:board) }
    let(:title) { 'test subject' }

    shared_examples "new" do
      it "works" do
        expect {
          perform_enqueued_jobs do
            create(:post, user: author, unjoined_authors: [coauthor], board: board, subject: title)
          end
        }.to change { Notification.count }.by(1)
        author_msg = Notification.where(user: notified).last
        expect(author_msg.notification_type).to eq('new_favorite_post')
        expect(author_msg.post).to eq(Post.last)
      end

      it "does not send for private posts" do
        expect {
          perform_enqueued_jobs do
            create(:post, user: author, board: board, privacy: :private)
          end
        }.not_to change { Notification.count }
      end

      it "does not send to readers for full accounts privacy posts" do
        unnotified = create(:reader_user)
        create(:favorite, user: unnotified, favorite: author)
        perform_enqueued_jobs do
          create(:post, user: author, board: board, privacy: :full_accounts)
        end

        # don't use change format because other non-reader users may be notified
        expect(Message.where(recipient_id: unnotified.id).count).to eq(0)
      end

      it "does not send to non-viewers for access-locked posts" do
        unnotified = create(:user)
        create(:favorite, user: unnotified, favorite: favorite)
        expect {
          perform_enqueued_jobs do
            create(:post, user: author, board: board, unjoined_authors: [coauthor], privacy: :access_list, viewers: [coauthor, notified])
          end
        }.to change { Notification.count }.by(1)
        expect(Notification.where(user: unnotified)).not_to be_present
      end

      it "does not send if reader has config disabled" do
        notified.update!(favorite_notifications: false)
        expect {
          perform_enqueued_jobs do
            create(:post, user: author, board: board)
          end
        }.not_to change { Notification.count }
      end

      it "does not send to authors" do
        Favorite.delete_all
        [author, coauthor, unjoined].each do |u|
          create(:favorite, user: u, favorite: favorite) unless u == favorite
        end

        expect {
          perform_enqueued_jobs do
            create(:post, user: author, board: board, unjoined_authors: [coauthor])
          end
        }.not_to change { Notification.count }
      end

      it "does not queue on imported posts" do
        create(:post, user: author, board: board, is_import: true)
        expect(NotifyFollowersOfNewPostJob).not_to have_been_enqueued
      end
    end

    context "with favorited author" do
      let(:favorite) { author }

      before(:each) { create(:favorite, user: notified, favorite: author) }

      include_examples "new"

      it "works for self-threads" do
        expect {
          perform_enqueued_jobs do
            create(:post, user: author, unjoined_authors: [], board: board, subject: title)
          end
        }.to change { Notification.count }.by(1)

        author_msg = Notification.where(user: notified).last
        expect(author_msg.notification_type).to eq('new_favorite_post')
        expect(author_msg.post).to eq(Post.last)
      end
    end

    context "with favorited coauthor" do
      let(:favorite) { coauthor }

      before(:each) { create(:favorite, user: notified, favorite: coauthor) }

      include_examples "new"
    end

    context "with favorited board" do
      let(:favorite) { board }

      before(:each) { create(:favorite, user: notified, favorite: board) }

      include_examples "new"

      it "does not send twice if the user has favorited both the poster and the continuity" do
        create(:favorite, user: notified, favorite: author)
        expect {
          perform_enqueued_jobs do
            create(:post, user: author, board: board)
          end
        }.to change { Notification.count }.by(1)
      end
    end

    describe "with blocking" do
      let(:post) { create(:post, user: author, board: board, authors: [coauthor]) }

      before(:each) { create(:favorite, user: notified, favorite: board) }

      it "does not send to users the poster has blocked" do
        create(:block, blocking_user: author, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { post } }.not_to change { Notification.count }
      end

      it "does not send to users a coauthor has blocked" do
        create(:block, blocking_user: coauthor, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { post } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking the poster" do
        create(:block, blocked_user: author, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { post } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking a coauthor" do
        create(:block, blocked_user: coauthor, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { post } }.not_to change { Notification.count }
      end
    end
  end

  context "on joined posts" do
    let(:author) { create(:user) }
    let(:coauthor) { create(:user) }
    let(:unjoined) { create(:user) }
    let(:replier) { create(:user) }
    let(:notified) { create(:user) }

    context "with both authors favorited" do
      before(:each) do
        create(:favorite, user: notified, favorite: author)
        create(:favorite, user: notified, favorite: replier)
      end

      it "does not send twice if the user has favorited both the poster and the replier" do
        expect {
          perform_enqueued_jobs do
            post = create(:post, user: author)
            create(:reply, post: post, user: replier)
          end
        }.to change { Notification.count }.by(1)
      end

      it "does not send twice if the poster changes their username" do
        expect {
          perform_enqueued_jobs do
            post = create(:post, user: author)
            author.update!(username: author.username + 'new')
            create(:reply, post: post, user: replier)
          end
        }.to change { Notification.count }.by(1)
      end

      it "does not send twice if the post subject changes" do
        expect {
          perform_enqueued_jobs do
            post = create(:post, user: author)
            post.update!(subject: post.subject + 'new')
            create(:reply, post: post, user: replier)
          end
        }.to change { Notification.count }.by(1)
      end

      it "does not send twice if notified by message" do
        now = Time.zone.now
        post = Timecop.freeze(now - 30.seconds) do
          create(:post, user: author, unjoined_authors: [replier])
        end
        msg_text = "#{author.username} has just posted a new post entitled #{post.subject} in the #{post.board.name} continuity"
        msg_text += " with #{replier.username}. #{ScrapePostJob.view_post(post.id)}"
        create(:message, subject: "New post by #{author.username}", message: msg_text, recipient: notified, sender_id: 0)
        expect {
          perform_enqueued_jobs do
            create(:reply, post: post, user: replier)
          end
        }.not_to change { Notification.count }
      end

      it "sends twice for different posts" do
        expect {
          perform_enqueued_jobs { create(:post, user: author) }
        }.to change { Notification.count }.by(1)

        not_favorited_post = nil
        expect {
          perform_enqueued_jobs do
            not_favorited_post = create(:post)
          end
        }.not_to change { Notification.count }

        expect {
          perform_enqueued_jobs do
            create(:reply, post: not_favorited_post, user: replier)
          end
        }.to change { Notification.count }.by(1)
      end
    end

    context "with favorited replier" do
      before(:each) { create(:favorite, user: notified, favorite: replier) }

      it "sends the right message" do
        post = create(:post, user: author)

        expect {
          perform_enqueued_jobs do
            create(:reply, post: post, user: replier)
          end
        }.to change { Notification.count }.by(1)

        message = Notification.last
        expect(message.user).to eq(notified)
        expect(message.notification_type).to eq('joined_favorite_post')
        expect(message.post).to eq(post)
      end

      it "does not send unless visible" do
        expect {
          perform_enqueued_jobs do
            post = create(:post, privacy: :access_list, viewers: [replier])
            create(:reply, post: post, user: replier)
          end
        }.not_to change { Notification.count }
      end

      it "does not send if reader has config disabled" do
        notified.update!(favorite_notifications: false)
        expect { perform_enqueued_jobs { create(:reply, user: replier) } }.not_to change { Notification.count }
      end

      it "does not queue on imported replies" do
        post = create(:post)
        clear_enqueued_jobs
        create(:reply, user: replier, post: post, is_import: true)
        expect(NotifyFollowersOfNewPostJob).not_to have_been_enqueued
      end
    end

    it "does not send to authors" do
      Favorite.delete_all
      [author, coauthor, unjoined].each do |u|
        create(:favorite, user: u, favorite: replier)
      end

      post = create(:post, user: author, unjoined_authors: [coauthor, unjoined, replier])
      create(:reply, user: coauthor, post: post)

      expect {
        perform_enqueued_jobs do
          create(:reply, user: replier, post: post)
        end
      }.not_to change { Notification.count }
    end

    describe "with blocking" do
      let(:coauthor) { create(:user) }
      let!(:post) { create(:post, user: author, unjoined_authors: [coauthor]) }
      let(:reply) { create(:reply, post: post, user: replier) }

      before(:each) { create(:favorite, user: notified, favorite: replier) }

      it "does not send to users the joining user has blocked" do
        create(:block, blocking_user: replier, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { reply } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking the joining user" do
        create(:block, blocked_user: replier, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { reply } }.not_to change { Notification.count }
      end

      it "does not send to users the original poster has blocked" do
        create(:block, blocking_user: author, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { reply } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking the original poster" do
        create(:block, blocked_user: author, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { reply } }.not_to change { Notification.count }
      end

      it "does not send to users who a coauthor has blocked" do
        create(:block, blocking_user: coauthor, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { reply } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking a coauthor" do
        create(:block, blocked_user: coauthor, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { reply } }.not_to change { Notification.count }
      end
    end
  end

  context "on newly accessible posts" do
    let!(:author) { create(:user) }
    let!(:coauthor) { create(:user) }
    let!(:unjoined) { create(:user) }
    let!(:notified) { create(:user) }
    let!(:post) { create(:post, user: author, unjoined_authors: [coauthor, unjoined], privacy: :access_list, viewers: [coauthor, unjoined]) }

    before(:each) { create(:reply, user: coauthor, post: post) }

    shared_examples "access" do
      it "works" do
        expect {
          perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) }
        }.to change { Notification.count }.by(1)

        notif = Notification.last
        expect(notif.user).to eq(notified)
        expect(notif.notification_type).to eq('accessible_favorite_post')
        expect(notif.post).to eq(post)
      end

      it "does not send on post creation" do
        board = post.board
        clear_enqueued_jobs
        expect {
          perform_enqueued_jobs do
            create(:post, user: author, unjoined_authors: [coauthor, unjoined], board: board)
          end
        }.not_to change { Notification.where(notification_type: :accessible_favorite_post).count }
      end

      it "does not send for public threads" do
        post.update!(privacy: :public)
        expect {
          perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) }
        }.not_to change { Notification.count }
      end

      it "does not send for private threads" do
        post.update!(privacy: :private)
        expect {
          perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) }
        }.not_to change { Notification.count }
      end

      it "does not send if reader has config disabled" do
        notified.update!(favorite_notifications: false)
        expect {
          perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) }
        }.not_to change { Notification.count }
      end

      it "does not send to authors" do
        Favorite.delete_all
        PostViewer.delete_all
        authors = [author, coauthor, unjoined].reject{ |u| u == favorite }

        authors.each do |user|
          create(:favorite, user: user, favorite: favorite)
          expect {
            perform_enqueued_jobs { PostViewer.create!(user: user, post: post) }
          }.not_to change { Notification.count }
        end
      end
    end

    context "with favorited author" do
      before(:each) { create(:favorite, user: notified, favorite: author) }

      include_examples "access"

      it "works for self-threads" do
        expect {
          perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) }
        }.to change { Notification.count }.by(1)

        notif = Notification.last
        expect(notif.user).to eq(notified)
        expect(notif.notification_type).to eq('accessible_favorite_post')
        expect(notif.post).to eq(post)
      end
    end

    context "with favorited coauthor" do
      before(:each) { create(:favorite, user: notified, favorite: coauthor) }

      include_examples "access"
    end

    context "with favorited unjoined coauthor" do
      before(:each) { create(:favorite, user: notified, favorite: unjoined) }

      include_examples "access"
    end

    context "with favorited board" do
      before(:each) { create(:favorite, user: notified, favorite: post.board) }

      include_examples "access"

      it "does not send twice if the user has favorited both the poster and the continuity" do
        create(:favorite, user: notified, favorite: author)
        expect {
          perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) }
        }.to change { Notification.count }.by(1)
      end
    end

    context "with privacy change" do
      before(:each) do
        create(:favorite, user: notified, favorite: author)
        post.update!(privacy: :private, viewers: [coauthor, unjoined, notified])
        clear_enqueued_jobs
      end

      it "works" do
        expect {
          perform_enqueued_jobs { post.update!(privacy: :access_list) }
        }.to change { Notification.count }.by(1)
      end

      it "does not send twice for new viewer" do
        PostViewer.find_by(user: notified, post: post).destroy!
        post.reload
        expect {
          perform_enqueued_jobs do
            post.update!(privacy: :access_list, viewers: [coauthor, unjoined, notified])
          end
        }.to change { Notification.count }.by(1)
      end

      it "does not send if already notified" do
        post.update!(privacy: :access_list, viewers: [coauthor, unjoined])
        expect {
          perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) }
        }.to change { Notification.count }.by(1)

        post.update!(privacy: :private)

        expect {
          perform_enqueued_jobs { post.update!(privacy: :access_list) }
        }.not_to change { Notification.count }
      end

      it "does not send for public threads" do
        expect {
          perform_enqueued_jobs { post.update!(privacy: :public) }
        }.not_to change { Notification.where(notification_type: :accessible_favorite_post).count }
      end

      it "does not send for registered threads" do
        expect {
          perform_enqueued_jobs { post.update!(privacy: :registered) }
        }.not_to change { Notification.where(notification_type: :accessible_favorite_post).count }
      end

      it "does not send for previously public threads" do
        post.update!(privacy: :public)
        post.reload
        clear_enqueued_jobs
        expect { perform_enqueued_jobs { post.update!(privacy: :access_list) } }.not_to change { Notification.count }
      end

      it "does not send if reader has config disabled" do
        notified.update!(favorite_notifications: false)
        expect {
          perform_enqueued_jobs { post.update!(privacy: :access_list) }
        }.not_to change { Notification.count }
      end
    end

    context "with blocking" do
      let!(:post) { create(:post, user: author, authors: [coauthor]) }
      let(:viewer) { PostViewer.create!(user: notified, post: post) }

      before(:each) { create(:favorite, user: notified, favorite: post.board) }

      it "does not send to users the poster has blocked" do
        create(:block, blocking_user: author, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { viewer } }.not_to change { Notification.count }
      end

      it "does not send to users a coauthor has blocked" do
        create(:block, blocking_user: coauthor, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { viewer } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking the poster" do
        create(:block, blocked_user: author, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { viewer } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking a coauthor" do
        create(:block, blocked_user: coauthor, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { viewer } }.not_to change { Notification.count }
      end
    end
  end
end
