RSpec.describe PostsController, 'POST unhide' do
  it "requires login" do
    post :unhide
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "succeeds for posts" do
    hidden_post = create(:post)
    stay_hidden_post = create(:post)
    user = create(:user)
    hidden_post.ignore(user)
    stay_hidden_post.ignore(user)
    login_as(user)
    post :unhide, params: { unhide_posts: [hidden_post.id] }
    expect(response).to redirect_to(hidden_posts_url)
    hidden_post.reload
    stay_hidden_post.reload
    expect(hidden_post).not_to be_ignored_by(user)
    expect(stay_hidden_post).to be_ignored_by(user)
  end

  it "works for reader users" do
    user = create(:reader_user)
    posts = create_list(:post, 2)
    login_as(user)
    post :unhide, params: { unhide_posts: posts.map(&:id).map(&:to_s) }
    expect(response).to redirect_to(hidden_posts_url)
  end

  it "succeeds for board" do
    board = create(:board)
    stay_hidden_board = create(:board)
    user = create(:user)
    board.ignore(user)
    stay_hidden_board.ignore(user)
    login_as(user)
    post :unhide, params: { unhide_boards: [board.id] }
    expect(response).to redirect_to(hidden_posts_url)
    board.reload
    stay_hidden_board.reload
    expect(board).not_to be_ignored_by(user)
    expect(stay_hidden_board).to be_ignored_by(user)
  end

  it "succeeds for both" do
    board = create(:board)
    hidden_post = create(:post)
    user = create(:user)
    board.ignore(user)
    hidden_post.ignore(user)
    login_as(user)

    post :unhide, params: { unhide_boards: [board.id], unhide_posts: [hidden_post.id] }

    expect(response).to redirect_to(hidden_posts_url)
    board.reload
    hidden_post.reload
    expect(board).not_to be_ignored_by(user)
    expect(hidden_post).not_to be_ignored_by(user)
  end

  it "succeeds for neither" do
    login
    post :unhide
    expect(response).to redirect_to(hidden_posts_url)
  end
end
