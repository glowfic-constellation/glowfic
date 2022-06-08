RSpec.describe NotifyFollowersOfNewPostJob do
  include ActiveJob::TestHelper

  let(:author) { create(:user) }
  let(:coauthor) { create(:user) }
  let(:unjoined) { create(:user) }
  let(:notified) { create(:user) }
  let(:board) { create(:board) }

  before(:each) { clear_enqueued_jobs }

  context "validations" do
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
  end

  shared_examples "general" do
    it "works" do
      expect { perform_enqueued_jobs { do_action } }.to change { Notification.where(user: notified).count }.by(1)
      notif = Notification.where(user: notified).last
      expect(notif.notification_type).to eq(type)
      expect(notif.post).to eq(Post.last)
    end

    it "does not send if reader has config disabled" do
      notified.update!(favorite_notifications: false)
      expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.where(user: notified).count }
    end
  end

  shared_examples 'authors' do
    it "does not send to authors" do
      Favorite.delete_all
      authors = [author, coauthor, unjoined].reject { |u| u == favorite }
      authors.each { |u| create(:favorite, user: u, favorite: favorite) }
      expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.where.not(notification_type: :coauthor_invitation).count }
    end
  end

  shared_examples 'privacy' do
    it "does not send for private posts" do
      expect { perform_enqueued_jobs { do_action(privacy: :private) } }.not_to change { Notification.count }
    end

    it "does not send to readers for full accounts privacy posts" do
      unnotified = create(:reader_user)
      create(:favorite, user: unnotified, favorite: author)
      perform_enqueued_jobs do
        create(:post, user: author, board: board, privacy: :full_accounts)
      end

      expect { perform_enqueued_jobs { do_action(privacy: :full_accounts) } }.not_to change { Notification.count }
      expect(Notification.where(user: unnotified)).not_to be_present
    end

    it "does not send to non-viewers for access-locked posts" do
      unnotified = create(:user)
      create(:favorite, user: unnotified, favorite: favorite)
      expect {
        perform_enqueued_jobs { do_action(privacy: :access_list, viewers: [coauthor, notified]) }
      }.not_to change { Notification.where(user: unnotified).count }
    end
  end

  shared_examples 'blocking' do
    context "with blocking" do
      before(:each) { create(:favorite, user: notified, favorite: board) }

      it "does not send to users the poster has blocked" do
        create(:block, blocking_user: author, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.where(user: notified).count }
      end

      it "does not send to users a coauthor has blocked" do
        create(:block, blocking_user: coauthor, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.where(user: notified).count }
      end

      it "does not send to users who are blocking the poster" do
        create(:block, blocked_user: author, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.where(user: notified).count }
      end

      it "does not send to users who are blocking a coauthor" do
        create(:block, blocked_user: coauthor, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.where(user: notified).count }
      end
    end
  end

  context "on new posts" do
    let(:title) { 'test subject' }
    let(:post) { build(:post, user: author, unjoined_authors: [coauthor, unjoined], board: board, subject: title) }
    let(:type) { 'new_favorite_post' }

    def do_action(privacy: :public, viewers: [])
      post.assign_attributes(privacy: privacy, viewers: viewers)
      post.save!
    end

    shared_examples "new" do
      include_examples 'general'
      include_examples 'authors'
      include_examples 'privacy'

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
        }.to change { Notification.where(user: notified).count }.by(1)

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
        expect { perform_enqueued_jobs { do_action } }.to change { Notification.where(user: notified).count }.by(1)
      end
    end

    include_examples 'blocking'
  end

  context "on joined posts" do
    let(:replier) { create(:user) }
    let(:post) { create(:post, user: author, board: board, unjoined_authors: [coauthor, unjoined]) }
    let(:type) { 'joined_favorite_post' }

    def do_action(privacy: nil, viewers: [])
      post.update!(privacy: privacy, viewers: viewers) if privacy
      create(:reply, post: post, user: replier)
    end

    context "with both authors favorited" do
      before(:each) do
        create(:favorite, user: notified, favorite: author)
        create(:favorite, user: notified, favorite: replier)
      end

      it "does not send twice if the user has favorited both the poster and the replier" do
        expect {
          perform_enqueued_jobs do
            post
            create(:reply, post: post, user: replier)
          end
        }.to change { Notification.where(user: notified).count }.by(1)
      end

      it "does not send twice if the poster changes their username" do
        expect {
          perform_enqueued_jobs do
            post
            author.update!(username: author.username + 'new')
            create(:reply, post: post, user: replier)
          end
        }.to change { Notification.where(user: notified).count }.by(1)
      end

      it "does not send twice if the post subject changes" do
        expect {
          perform_enqueued_jobs do
            post.update!(subject: post.subject + 'new')
            create(:reply, post: post, user: replier)
          end
        }.to change { Notification.where(user: notified).count }.by(1)
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
          perform_enqueued_jobs { post }
        }.to change { Notification.where(user: notified).count }.by(1)

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
      let(:favorite) { replier }

      before(:each) do
        create(:reply, user: coauthor, post: post)
        create(:favorite, user: notified, favorite: replier)
      end

      include_examples 'general'
      include_examples 'privacy'
      include_examples 'authors'

      it "does not queue on imported replies" do
        clear_enqueued_jobs
        create(:reply, user: replier, post: post, is_import: true)
        expect(NotifyFollowersOfNewPostJob).not_to have_been_enqueued
      end

      it "does not queue if replier is already an unjoined author" do
        post.update!(unjoined_authors: [coauthor, unjoined, replier])
        clear_enqueued_jobs
        create(:reply, user: replier, post: post)
        expect(NotifyFollowersOfNewPostJob).not_to have_been_enqueued
      end
    end

    describe "with blocking" do
      before(:each) do
        create(:reply, user: coauthor, post: post)
        create(:favorite, user: notified, favorite: replier)
      end

      it "does not send to users the joining user has blocked" do
        create(:block, blocking_user: replier, blocked_user: notified, hide_me: :posts)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.count }
      end

      it "does not send to users who are blocking the joining user" do
        create(:block, blocked_user: replier, blocking_user: notified, hide_them: :posts)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.count }
      end
    end

    include_examples 'blocking'
  end

  context "on newly accessible posts" do
    let(:type) { 'accessible_favorite_post' }
    let(:post) do
      create(:post, user: author, unjoined_authors: [coauthor, unjoined], board: board, privacy: :access_list, viewers: [coauthor, unjoined])
    end
    let(:do_action) { PostViewer.create!(user: notified, post: post) }

    before(:each) { create(:reply, user: coauthor, post: post) }

    shared_examples "access" do
      include_examples 'general'
      include_examples 'authors'

      it "does not send" do
        clear_enqueued_jobs
        expect {
          perform_enqueued_jobs do
            create(:post,
              user: author,
              privacy: :access_list,
              unjoined_authors: [coauthor, unjoined],
              viewers: [coauthor, unjoined, notified],
              board: board,
            )
          end
        }.not_to change { Notification.where(notification_type: :accessible_favorite_post).count }
      end

      it "does not send for public threads" do
        post.update!(privacy: :public)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.count }
      end

      it "does not send for private threads" do
        post.update!(privacy: :private)
        expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.count }
      end

      it "does not send to authors" do
        Favorite.delete_all
        PostViewer.delete_all
        authors = [author, coauthor, unjoined].reject { |u| u == favorite }

        authors.each do |user|
          create(:favorite, user: user, favorite: favorite)
          expect {
            perform_enqueued_jobs { PostViewer.create!(user: user, post: post) }
          }.not_to change { Notification.count }
        end
      end
    end

    context "with favorited author" do
      let(:favorite) { author }

      before(:each) { create(:favorite, user: notified, favorite: author) }

      include_examples "access"

      it "works for self-threads" do
        post = create(:post, user: author, board: board, privacy: :access_list)
        create(:reply, user: author, post: post)

        expect { perform_enqueued_jobs { PostViewer.create!(user: notified, post: post) } }.to change { Notification.count }.by(1)

        notif = Notification.last
        expect(notif.user).to eq(notified)
        expect(notif.notification_type).to eq('accessible_favorite_post')
        expect(notif.post).to eq(post)
      end
    end

    context "with favorited coauthor" do
      let(:favorite) { coauthor }

      before(:each) { create(:favorite, user: notified, favorite: coauthor) }

      include_examples "access"
    end

    context "with favorited unjoined coauthor" do
      let(:favorite) { unjoined }

      before(:each) { create(:favorite, user: notified, favorite: unjoined) }

      include_examples "access"
    end

    context "with favorited board" do
      let(:favorite) { board }

      before(:each) { create(:favorite, user: notified, favorite: board) }

      include_examples "access"

      it "does not send twice if the user has favorited both the poster and the continuity" do
        create(:favorite, user: notified, favorite: author)
        expect { perform_enqueued_jobs { do_action } }.to change { Notification.count }.by(1)
      end
    end

    context "with privacy change" do
      let(:do_action) { post.update!(privacy: :access_list) }

      before(:each) do
        create(:favorite, user: notified, favorite: author)
        post.update!(privacy: :private, viewers: [coauthor, unjoined, notified])
        clear_enqueued_jobs
      end

      include_examples 'general'

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
    end

    include_examples 'blocking'
  end

  context "on newly published posts" do
    let!(:post) { create(:post, user: author, board: board, authors: [coauthor, unjoined], privacy: :access_list) }
    let(:type) { 'published_favorite_post' }

    before(:each) { create(:reply, user: coauthor, post: post) }

    [:registered, :public].each do |privacy|
      context "to #{privacy}" do
        let(:do_action) { post.update!(privacy: privacy) }

        shared_examples "publication" do
          include_examples 'general'
          include_examples 'authors'

          it "works for previously private posts" do
            post.update!(privacy: :private)
            clear_enqueued_jobs

            expect { perform_enqueued_jobs { do_action } }.to change { Notification.count }.by(1)
            notif = Notification.where(user: notified).last
            expect(notif.notification_type).to eq('published_favorite_post')
            expect(notif.post_id).to eq(post.id)
          end

          it "does not send on post creation" do
            clear_enqueued_jobs
            expect {
              perform_enqueued_jobs do
                create(:post, user: author, board: board, authors: [coauthor, unjoined], privacy: :access_list)
              end
            }.not_to change { Notification.where(notification_type: :published_favorite_post).count }
          end
        end

        context "with favorited author" do
          let(:favorite) { author }

          before(:each) { create(:favorite, user: notified, favorite: author) }

          include_examples "publication"

          it "works for self-threads" do
            post = create(:post, user: author, board: board, privacy: :access_list)
            create(:reply, post: post, user: author)

            expect { perform_enqueued_jobs { post.update!(privacy: privacy) } }.to change { Notification.count }.by(1)

            notif = Notification.where(user: notified).last
            expect(notif.notification_type).to eq('published_favorite_post')
            expect(notif.post_id).to eq(post.id)
          end
        end

        context "with favorited coauthor" do
          let(:favorite) { coauthor }

          before(:each) { create(:favorite, user: notified, favorite: coauthor) }

          include_examples "publication"
        end

        context "with favorited board" do
          let(:favorite) { board }

          before(:each) { create(:favorite, user: notified, favorite: board) }

          include_examples "publication"

          it "does not send twice if the user has favorited both the poster and the continuity" do
            create(:favorite, user: notified, favorite: author)
            expect { perform_enqueued_jobs { do_action } }.to change { Notification.count }.by(1)
          end
        end

        context "with favorited unjoined coauthor" do
          let(:favorite) { unjoined }

          before(:each) { create(:favorite, user: notified, favorite: unjoined) }

          include_examples "publication"
        end

        include_examples 'blocking'
      end
    end
  end

  context "on revived posts" do
    let(:type) { 'resumed_favorite_post' }

    shared_examples "reactivation" do
      shared_examples "active" do
        include_examples 'general'
        include_examples 'authors'
        include_examples 'privacy'

        it "only notifies once" do
          create(:notification, notification_type: :resumed_favorite_post, post: post, user: notified, unread: true)
          expect { perform_enqueued_jobs { do_action } }.not_to change { Notification.count }
        end

        it "renotifies if previous notification is read" do
          create(:notification, notification_type: :resumed_favorite_post, post: post, user: notified, unread: false)
          expect { perform_enqueued_jobs { do_action } }.to change { Notification.count }.by(1)
        end
      end

      context "with favorited author" do
        let(:favorite) { author }

        before(:each) { create(:favorite, user: notified, favorite: author) }

        include_examples 'active'

        it "works for self-threads" do
          post.last_reply.update_columns(user_id: author.id) # rubocop:disable Rails/SkipsModelValidations
          post.post_authors.where.not(user_id: author.id).delete_all

          expect { perform_enqueued_jobs { do_action } }.to change { Notification.count }.by(1)

          notif = Notification.where(user: notified).last
          expect(notif.notification_type).to eq('resumed_favorite_post')
          expect(notif.post_id).to eq(post.id)
        end

        it "works with only top post" do
          post.last_reply.destroy!
          expect { perform_enqueued_jobs { do_action } }.to change { Notification.count }.by(1)
        end
      end

      context "with favorited coauthor" do
        let(:favorite) { coauthor }

        before(:each) { create(:favorite, user: notified, favorite: coauthor) }

        include_examples 'active'
      end

      context "with favorited unjoined coauthor" do
        let(:favorite) { unjoined }

        before(:each) { create(:favorite, user: notified, favorite: unjoined) }

        include_examples 'active'
      end

      context "with favorited board" do
        let(:favorite) { board }

        before(:each) { create(:favorite, user: notified, favorite: board) }

        include_examples 'active'

        it "does not send twice if the user has favorited both the poster and the continuity" do
          create(:favorite, user: notified, favorite: author)
          expect { perform_enqueued_jobs { do_action } }.to change { Notification.count }.by(1)
        end
      end

      context "with favorited post" do
        let(:favorite) { post }

        before(:each) { create(:favorite, user: notified, favorite: post) }

        include_examples 'active'
      end

      include_examples 'blocking'
    end

    context "with abandoned posts" do
      let(:post) { create(:post, user: author, board: board, authors: [coauthor, unjoined]) }

      before(:each) do
        create(:reply, user: coauthor, post: post)
        post.update!(status: :abandoned)
      end

      def do_action(privacy: nil, viewers: [])
        if privacy
          post.update!(privacy: privacy, viewers: viewers, status: :active)
        else
          post.update!(status: :active)
        end
      end

      include_examples "reactivation"
    end

    context "with manually hiatused posts" do
      let(:post) { create(:post, user: author, board: board, authors: [coauthor, unjoined]) }

      before(:each) do
        create(:reply, user: coauthor, post: post)
        post.update!(status: :hiatus)
      end

      def do_action(privacy: nil, viewers: [])
        post.update!(privacy: privacy, viewers: viewers, is_import: true) if privacy
        create(:reply, user: author, post: post)
      end

      include_examples "reactivation"
    end

    context "with auto-hiatused posts" do
      let(:now) { Time.zone.now }
      let!(:post) do
        Timecop.freeze(now - 2.months) do
          create(:post, user: author, board: board, authors: [coauthor, unjoined])
        end
      end

      before(:each) do
        Timecop.freeze(now - 2.months + 1.day) do
          create(:reply, user: coauthor, post: post)
        end
      end

      def do_action(privacy: nil, viewers: [])
        if privacy
          Timecop.freeze(now - 2.months) do
            post.update!(privacy: privacy, viewers: viewers, is_import: true)
          end
        end

        Timecop.freeze(now) do
          create(:reply, user: author, post: post)
        end
      end

      include_examples "reactivation"
    end
  end
end
