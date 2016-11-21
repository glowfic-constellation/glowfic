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
      expect(assigns(:character)).to eq(character)
    end
  end

  describe "GET show" do
    it "does not require login" do
      post = create(:post)
      get :show, id: post.id
      expect(response.status).to eq(200)
    end

    # TODO WAY more tests
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
end
