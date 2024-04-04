RSpec.describe PostsController, 'POST unhide' do
  it "requires login" do
    post :unhide
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  context "succeeds for" do
    let(:user) { create(:user) }
    let(:hidden_post) { create(:post) }
    let(:hidden_board) { create(:board) }

    before(:each) { login_as(user) }

    it "posts" do
      stay_hidden_post = create(:post)

      hidden_post.ignore(user)
      stay_hidden_post.ignore(user)

      post :unhide, params: { unhide_posts: [hidden_post.id] }

      expect(response).to redirect_to(hidden_posts_url)
      expect(hidden_post.reload).not_to be_ignored_by(user)
      expect(stay_hidden_post.reload).to be_ignored_by(user)
    end

    it "reader users" do
      user.update!(role_id: :read_only)
      post :unhide, params: { unhide_posts: [hidden_post.id] }
      expect(response).to redirect_to(hidden_posts_url)
    end

    it "board" do
      stay_hidden_board = create(:board)

      hidden_board.ignore(user)
      stay_hidden_board.ignore(user)

      post :unhide, params: { unhide_boards: [hidden_board.id] }

      expect(response).to redirect_to(hidden_posts_url)
      expect(hidden_board.reload).not_to be_ignored_by(user)
      expect(stay_hidden_board.reload).to be_ignored_by(user)
    end

    it "posts and board" do
      hidden_board.ignore(user)
      hidden_post.ignore(user)

      post :unhide, params: { unhide_boards: [hidden_board.id], unhide_posts: [hidden_post.id] }

      expect(response).to redirect_to(hidden_posts_url)
      expect(hidden_board.reload).not_to be_ignored_by(user)
      expect(hidden_post.reload).not_to be_ignored_by(user)
    end

    it "neither" do
      post :unhide
      expect(response).to redirect_to(hidden_posts_url)
    end
  end
end
