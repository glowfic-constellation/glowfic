RSpec.describe NotificationsController do
  describe "GET index" do
    let(:user) { create(:user) }

    it "requires login" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "with views" do
      render_views
      it "works" do
        notifications = create_list(:notification, 3, user: user, notification_type: :new_favorite_post)
        notifications += create_list(:notification, 2, user: user, notification_type: :joined_favorite_post)
        notifications += create_list(:notification, 2, user: user, notification_type: :import_success)
        notifications << create(:notification, user: user, notification_type: :import_fail)
        post_ids = notifications.map(&:post_id)
        notifications << create(:error_notification, user: user)
        create_list(:notification, 3)
        login_as(user)
        get :index
        expect(assigns(:notifications).map(&:id)).to match_array(notifications.map(&:id))
        expect(assigns(:posts).keys).to match_array(post_ids)
        expect(flash[:error]).not_to be_present
      end
    end

    it "paginates" do
      create_list(:notification, 3, user: user)
      notifications = create_list(:notification, 22, user: user)
      notifications += create_list(:error_notification, 3, user: user)
      post_ids = notifications.map(&:post_id).compact_blank
      login_as(user)
      get :index
      expect(assigns(:notifications).map(&:id)).to match_array(notifications.map(&:id))
      expect(assigns(:posts).keys).to match_array(post_ids)
      expect(flash[:error]).not_to be_present
    end

    it "handles later pages" do
      notifications = create_list(:notification, 15, user: user)
      create_list(:notification, 25, user: user)
      post_ids = notifications.map(&:post_id).compact_blank
      login_as(user)
      get :index, params: { page: 2 }
      expect(assigns(:notifications).map(&:id)).to match_array(notifications.map(&:id))
      expect(assigns(:posts).keys).to match_array(post_ids)
      expect(flash[:error]).not_to be_present
    end

    it "respects post visibility" do
      create(:notification, user: user, notification_type: :new_favorite_post, post: create(:post, privacy: :private))
      create(:notification, user: user, notification_type: :new_favorite_post, post: create(:post, privacy: :access_list))
      accessible = create(:post, privacy: :access_list, viewers: [user])
      visible = [create(:notification, user: user, notification_type: :new_favorite_post, post: accessible)]
      visible << create(:notification, user: user, notification_type: :new_favorite_post, post: create(:post, privacy: :registered))
      visible += create_list(:notification, 2, user: user)
      visible += create_list(:error_notification, 2, user: user)

      blocked_user = create(:user)
      create(:block, blocking_user: user, blocked_user: blocked_user, hide_them: :posts)
      hidden_posts = create_list(:post, 2, user: blocked_user, authors_locked: true)
      expect(user.hidden_posts).to match_array(hidden_posts.map(&:id))
      hidden_posts.each { |post| create(:notification, user: user, post: post) }

      blocking_user = create(:user)
      create(:block, blocking_user: blocking_user, blocked_user: user, hide_me: :all)
      blocked_posts = create_list(:post, 2, user: blocking_user, authors_locked: true)
      expect(user.blocked_posts).to match_array(blocked_posts.map(&:id))
      blocked_posts.each { |post| create(:notification, user: user, post: post) }

      ignored_board = create(:board)
      ignored_board.ignore(user)
      visible << create(:notification, user: user, notification_type: :new_favorite_post, post: create(:post, board: ignored_board))

      ignored_post = create(:post)
      ignored_post.ignore(user)
      visible << create(:notification, user: user, notification_type: :new_favorite_post, post: ignored_post)

      login_as(user)
      get :index
      expect(assigns(:notifications).map(&:id)).to match_array(visible.map(&:id))
      expect(flash[:error]).not_to be_present
    end

    it "respects ignored posts" do
      user.update!(hide_from_all: true)

      ignored_board = create(:board)
      create(:notification, user: user, notification_type: :new_favorite_post, post: create(:post, board: ignored_board))
      ignored_board.ignore(user)

      ignored_post = create(:post)
      create(:notification, user: user, notification_type: :new_favorite_post, post: ignored_post)
      ignored_post.ignore(user)

      visible_post = create(:post)
      visible_notif = create(:notification, user: user, notification_type: :new_favorite_post, post: visible_post)

      login_as(user)
      get :index
      expect(assigns(:notifications)).to eq([visible_notif])
      expect(flash[:error]).not_to be_present
    end
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid action" do
      login
      post :mark
      expect(response).to redirect_to(notifications_url)
      expect(flash[:error]).to eq("Could not perform unknown action.")
    end

    context "marking unread" do
      let!(:notification) { create(:notification, unread: false) }

      it "handles invalid notification ids" do
        login
        post :mark, params: { marked_ids: ['nope', -1, '0'], commit: "Mark Unread" }
        expect(notification.reload.unread).to eq(false)
      end

      it "does not work the wrong user" do
        login
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Mark Unread" }
        expect(notification.reload.unread).to eq(false)
      end

      it "works unread for user" do
        notification.update!(unread: true)
        login_as(notification.user)
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Mark Unread" }
        expect(notification.reload.unread).to eq(true)
      end

      it "works read for user" do
        login_as(notification.user)
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Mark Unread" }
        expect(notification.reload.unread).to eq(true)
      end
    end

    context "marking read" do
      let!(:notification) { create(:notification, unread: true) }

      it "handles invalid notification ids" do
        login
        post :mark, params: { marked_ids: ['nope', -1, '0'], commit: "Mark Read" }
        expect(notification.reload.unread).to eq(true)
      end

      it "does not work for the wrong user" do
        login
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Mark Read" }
        expect(notification.reload.unread).to eq(true)
      end

      it "works unread for user" do
        login_as(notification.user)
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Mark Read" }
        expect(notification.reload.unread).to eq(false)
      end

      it "works read for user" do
        notification.update!(unread: false)
        login_as(notification.user)
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Mark Read" }
        expect(notification.reload.unread).to eq(false)
      end
    end

    context "deleting" do
      let!(:notification) { create(:notification) }

      it "handles invalid notification ids" do
        login
        post :mark, params: { marked_ids: ['nope', -1, '0'], commit: "Delete" }
        expect(Notification.find_by(id: notification.id)).to be_present
      end

      it "does not work for other users" do
        login
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Delete" }
        expect(Notification.find_by(id: notification.id)).to be_present
      end

      it "works for user" do
        login_as(notification.user)
        post :mark, params: { marked_ids: [notification.id.to_s], commit: "Delete" }
        expect(Notification.find_by(id: notification.id)).not_to be_present
      end
    end
  end
end
