RSpec.describe FlatPostsController do
  describe "GET #show" do
    let(:post) { create(:post) }

    it "redirects to continuities when the post is missing" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to include('not be found')
    end

    it "redirects when the post is not visible to the user" do
      private_post = create(:post, privacy: :private)
      get :show, params: { id: private_post.id }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to include('permission')
    end

    it "renders the chrome around the flat body marker for a visible post" do
      get :show, params: { id: post.id }
      expect(response.status).to eq(200)
      expect(response.body).to include(post.subject)
    end
  end
end
