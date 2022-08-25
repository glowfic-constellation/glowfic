RSpec.describe PostsController, 'GET stats' do
  let(:post) { create(:post) }

  it "requires post" do
    login
    get :stats, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "calculates OpenGraph meta" do
    user = create(:user, username: 'example user')
    board = create(:board, name: 'board')
    post = create(:post, subject: 'title', user: user, board: board)
    get :stats, params: { id: post.id }

    meta_og = assigns(:meta_og)
    expect(meta_og[:url]).to eq(stats_post_url(post))
    expect(meta_og[:title]).to eq('title · board » Stats')
    expect(meta_og[:description]).to eq('(example user)')
  end

  it "works logged out" do
    get :stats, params: { id: post.id }
    expect(response.status).to eq(200)
  end

  it "works logged in" do
    login
    get :stats, params: { id: post.id }
    expect(response.status).to eq(200)
  end

  it "works for reader account" do
    login_as(create(:reader_user))
    get :stats, params: { id: post.id }
    expect(response).to have_http_status(200)
  end
end
