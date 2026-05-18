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

    it "responds successfully for a visible post" do
      # Body content isn't asserted here because ActionController::Live
      # writes through response.stream in a separate thread, and the
      # controller-spec harness doesn't materialize that back into
      # `response.body`. Integration coverage for the body content lives
      # in spec/models/flat_post_spec.rb (#stream_body_to).
      get :show, params: { id: post.id }
      expect(response.status).to eq(200)
    end
  end
end
