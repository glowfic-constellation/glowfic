RSpec.describe PostsController, 'GET search' do
  context "no search" do
    it "works logged out" do
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Posts')
      expect(assigns(:search_results)).to be_nil
    end

    it "works logged in" do
      login
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Posts')
      expect(assigns(:search_results)).to be_nil
    end

    it "works for reader account" do
      login_as(create(:reader_user))
      get :search
      expect(response).to have_http_status(200)
    end
  end

  context "searching" do
    let(:controller_action) { "search" }
    let(:params) { { commit: true } }
    let(:assign_variable) { :search_results }

    it "restricts to visible posts" do
      create(:post, subject: 'contains stars', privacy: :private)
      post = create(:post, subject: 'visible contains stars')
      get :search, params: { commit: true, subject: 'stars' }
      expect(assigns(:search_results)).to match_array([post])
    end

    context "when logged out" do
      include_examples "logged out post list"
    end

    context "when logged in" do
      include_examples "logged in post list"
    end
  end
end
