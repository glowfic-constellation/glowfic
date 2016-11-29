require "spec_helper"

RSpec.describe PostsController do
  describe "GET index" do
    it "has a 200 status code" do
      get :index
      expect(response.status).to eq(200)
    end

    it "paginates" do
      26.times do create(:post) end
      get :index
      num_posts_fetched = controller.instance_variable_get('@posts').total_pages
      expect(num_posts_fetched).to eq(2)
    end

    it "only fetches most recent threads" do
      26.times do create(:post) end
      oldest = Post.order('id asc').first
      get :index
      ids_fetched = controller.instance_variable_get('@posts').map(&:id)
      expect(ids_fetched).not_to include(oldest.id)
    end

    it "only fetches most recent threads based on updated_at" do
      26.times do create(:post) end
      oldest = Post.order('id asc').first
      next_oldest = Post.order('id asc').second
      oldest.update_attributes(content: "just to make it update")
      get :index
      ids_fetched = controller.instance_variable_get('@posts').map(&:id)
      expect(ids_fetched).not_to include(next_oldest.id)
    end
  end

  describe "GET search" do
    skip
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "sets relevant fields" do
      user = create(:user)
      character = create(:character, user: user)
      user.update_attributes(active_character: character)
      user.reload
      login_as(user)

      get :new

      expect(response.status).to eq(200)
      expect(assigns(:post)).to be_new_record
      expect(assigns(:post).character).to eq(character)
    end
  end

  describe "POST create" do
    skip
  end

  describe "GET show" do
    it "does not require login" do
      post = create(:post)
      get :show, id: post.id
      expect(response.status).to eq(200)
    end

    # TODO WAY more tests
  end

  describe "GET history" do
    it "requires post" do
      login
      get :history, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "works logged out" do
      get :history, id: create(:post).id
      expect(response.status).to eq(200)
    end

    it "works logged in" do
      login
      get :history, id: create(:post).id
      expect(response.status).to eq(200)
    end
  end

  describe "GET stats" do
    it "requires post" do
      login
      get :stats, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "works logged out" do
      get :stats, id: create(:post).id
      expect(response.status).to eq(200)
    end

    it "works logged in" do
      login
      get :stats, id: create(:post).id
      expect(response.status).to eq(200)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires post" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires your post" do
      login
      post = create(:post)
      get :edit, id: post.id
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "sets relevant fields" do
      user = create(:user)
      character = create(:character, user: user)
      post = create(:post, user: user, character: character)
      expect(post.icon).to be_nil
      login_as(user)

      get :edit, id: post.id

      expect(response.status).to eq(200)
      expect(assigns(:post)).to eq(post)
      expect(assigns(:post).character).to eq(character)
      expect(assigns(:post).icon_id).to be_nil
    end
  end

  describe "PUT update" do
    skip
  end

  describe "POST warnings" do
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid post" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post permission" do
      user = create(:user)
      login_as(user)
      post = create(:post)
      expect(post).not_to be_editable_by(user)
      delete :destroy, id: post.id
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "succeeds" do
      post = create(:post)
      login_as(post.user)
      delete :destroy, id: post.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq("Post deleted.")
    end
  end

  describe "GET owed" do
    it "requires login" do
      get :owed
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds" do
      login
      get :owed
      expect(response.status).to eq(200)
    end

    # TODO WAY more tests
  end

  describe "GET unread" do
    it "requires login" do
      get :unread
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds" do
      login
      get :unread
      expect(response.status).to eq(200)
    end

    # TODO WAY more tests
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "read" do
      it "skips invisible post" do
        private_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
        user = create(:user)
        expect(private_post.visible_to?(user)).not_to be_true
        login_as(user)
        post :mark, marked_ids: [private_post.id], commit: "Mark Read"
        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("0 posts marked as read.")
        expect(private_post.reload.last_read(user)).to be_nil
      end

      it "reads posts" do
        user = create(:user)
        post1 = create(:post)
        post2 = create(:post)
        login_as(user)

        expect(post1.last_read(user)).to be_nil
        expect(post2.last_read(user)).to be_nil

        post :mark, marked_ids: [post1.id.to_s, post2.id.to_s], commit: "Mark Read"

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("2 posts marked as read.")
        expect(post1.reload.last_read(user)).not_to be_nil
        expect(post2.reload.last_read(user)).not_to be_nil
      end
    end

    context "ignored" do
      it "skips invisible post" do
        private_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
        user = create(:user)
        expect(private_post.visible_to?(user)).not_to be_true
        login_as(user)
        post :mark, marked_ids: [private_post.id]
        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("0 posts hidden from this page.")
        expect(private_post.reload.ignored_by?(user)).not_to be_true
      end

      it "ignores posts" do
        user = create(:user)
        post1 = create(:post)
        post2 = create(:post)
        login_as(user)

        expect(post1.visible_to?(user)).to be_true
        expect(post2.visible_to?(user)).to be_true

        post :mark, marked_ids: [post1.id.to_s, post2.id.to_s]

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("2 posts hidden from this page.")
        expect(post1.reload.ignored_by?(user)).to be_true
        expect(post2.reload.ignored_by?(user)).to be_true
      end
    end
  end

  describe "GET hidden" do
    it "requires login" do
      get :hidden
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds with no hidden" do
      login
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).to be_empty
      expect(assigns(:hidden_postviews)).to be_empty
    end

    it "succeeds with board hidden" do
      user = create(:user)
      board = create(:board)
      board.ignore(user)
      login_as(user)
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).not_to be_empty
      expect(assigns(:hidden_postviews)).to be_empty
    end

    it "succeeds with post hidden" do
      user = create(:user)
      post = create(:post)
      post.ignore(user)
      login_as(user)
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).to be_empty
      expect(assigns(:hidden_postviews)).not_to be_empty
    end

    it "succeeds with both hidden" do
      user = create(:user)
      post = create(:post)
      post.ignore(user)
      post.board.ignore(user)
      login_as(user)
      get :hidden
      expect(response.status).to eq(200)
      expect(assigns(:hidden_boardviews)).not_to be_empty
      expect(assigns(:hidden_postviews)).not_to be_empty
    end
  end

  describe "POST unhide" do
    skip
  end
end
