RSpec.describe PostsController, 'GET hidden' do
  it "requires login" do
    get :hidden
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "works for reader users" do
    user = create(:reader_user)
    login_as(user)
    get :hidden
    expect(response.status).to eq(200)
  end

  it "succeeds with no hidden" do
    login
    get :hidden
    expect(response.status).to eq(200)
    expect(assigns(:hidden_boardviews)).to be_empty
    expect(assigns(:hidden_posts)).to be_empty
  end

  it "succeeds with board hidden" do
    user = create(:user)
    board = create(:board)
    board.ignore(user)
    login_as(user)
    get :hidden
    expect(response.status).to eq(200)
    expect(assigns(:hidden_boardviews)).not_to be_empty
    expect(assigns(:hidden_posts)).to be_empty
  end

  it "succeeds with post hidden" do
    user = create(:user)
    post = create(:post)
    post.ignore(user)
    login_as(user)
    get :hidden
    expect(response.status).to eq(200)
    expect(assigns(:hidden_boardviews)).to be_empty
    expect(assigns(:hidden_posts)).not_to be_empty
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
    expect(assigns(:hidden_posts)).not_to be_empty
  end
end
