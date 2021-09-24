RSpec.describe PostsController, 'GET history' do
  let(:post) { create(:post) }

  it "requires post" do
    login
    get :history, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "works logged out" do
    get :history, params: { id: post.id }
    expect(response.status).to eq(200)
  end

  it "works logged in" do
    login
    get :history, params: { id: post.id }
    expect(response.status).to eq(200)
  end

  it "works for reader account" do
    login_as(create(:reader_user))
    get :history, params: { id: post.id }
    expect(response).to have_http_status(200)
  end

  context "with render_view" do
    render_views

    it "works" do
      Post.auditing_enabled = true
      post = create(:post)
      post.update!(privacy: :access_list)
      post.update!(continuity: create(:board))
      post.update!(content: 'new content')

      login_as(post.user)

      get :history, params: { id: post.id }

      expect(response.status).to eq(200)
      Post.auditing_enabled = false
    end
  end
end
