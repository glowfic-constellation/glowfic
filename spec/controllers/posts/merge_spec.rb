RSpec.describe PostsController do
  let(:user) { create(:user) }
  let(:coauthor) { create(:user) }
  let(:user_post) { create(:post, user: user) }

  describe "GET #merge" do
    it "requires login" do
      get :merge, params: { id: user_post.id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires edit permissions" do
      login
      get :merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires locked authorship" do
      login_as(user)
      user_post.update!(authors_locked: false)
      get :merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Post must be locked to current authors.")
    end

    it "works for creator if locked" do
      login_as(user)
      user_post.update!(authors_locked: true)
      get :merge, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end

    it "works for coauthor if locked" do
      login_as(coauthor)
      create(:reply, post: user_post, user: coauthor)
      user_post.update!(authors_locked: true)
      get :merge, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end

    it "works for mod if locked" do
      login_as(create(:mod_user))
      user_post.update!(authors_locked: true)
      get :merge, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end

    context "with render_views" do
      render_views

      it "renders" do
        login_as(user)
        user_post.update!(authors_locked: true)
        get :merge, params: { id: user_post.id }
        expect(response).to have_http_status(200)
        expect(response.body).to include("Merge Post")
      end
    end
  end

  describe "POST #preview_merge" do
    it "requires login" do
      post :preview_merge, params: { id: user_post.id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires edit permissions" do
      login
      post :preview_merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires locked authorship" do
      login_as(user)
      user_post.update!(authors_locked: false)
      post :preview_merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Post must be locked to current authors.")
    end
  end
end
