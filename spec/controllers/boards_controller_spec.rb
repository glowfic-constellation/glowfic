require "spec_helper"

RSpec.describe BoardsController do
  describe "GET index" do
    it "does not require login" do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end

    it "sets the correct cowriters" do
      user = create(:user)
      others = 3.times.collect do create(:user) end

      login_as(user)
      get :new

      expect(assigns(:users).count).to eq(3)
      expect(assigns(:users).map(&:id)).to eq(others.map(&:id))
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Continuity could not be created.")
      expect(response).to render_template('new')
    end

    it "successfully makes a board" do
      expect(Board.count).to eq(0)
      user_id = login
      post :create, board: {name: 'TestBoard'}
      expect(response).to redirect_to(boards_url)
      expect(flash[:success]).to eq("Continuity created!")
      expect(Board.count).to eq(1)
      expect(Board.first.name).to eq('TestBoard')
      expect(Board.first.creator_id).to eq(user_id)
    end
  end

  describe "GET show" do
    it "requires valid board" do
      get :show, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      get :show, id: board.id
      expect(response.status).to eq(200)
    end

    it "succeeds for logged in users with valid board" do
      login
      board = create(:board)
      get :show, id: board.id
      expect(response.status).to eq(200)
    end

    it "only fetches the board's first 25 posts" do
      board = create(:board)
      26.times do create(:post, board: board) end
      get :show, id: board.id
      expect(assigns(:posts).size).to eq(25)
    end

    it "orders the posts by updated_at" do
      board = create(:board)
      3.times do create(:post, board: board, updated_at: Time.now + rand(5..30).hours) end
      get :show, id: board.id
      expect(assigns(:posts)).to eq(assigns(:posts).sort_by(&:updated_at).reverse)
    end

    it "does not fetch posts the user cannot see" do
      board = create(:board)
      post = create(:post, board: board, privacy: Post::PRIVACY_PRIVATE)
      user = create(:user)
      expect(post).not_to be_visible_to(user)

      login_as(user)
      get :show, id: board.id
      expect(assigns(:posts)).not_to include(post)
    end
  end

  describe "GET edit" do
    skip
  end

  describe "PUT update" do
    skip
  end

  describe "DELETE destroy" do
    skip
  end

  describe "POST mark" do
    it "requires login" do
      post :mark
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires board id" do
      login
      post :mark
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid board id" do
      login
      post :mark, board_id: -1
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Continuity could not be found.")
    end

    it "requires valid action" do
      login
      post :mark, board_id: create(:board).id
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:error]).to eq("Please choose a valid action.")
    end

    it "successfully marks board read" do
      board = create(:board)
      user = create(:user)
      login_as(user)
      now = Time.now
      expect(board.last_read(user)).to be_nil
      post :mark, board_id: board.id, commit: "Mark Read"
      expect(Board.find(board.id).last_read(user)).to be >= now # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{board.name} marked as read.")
    end

    it "successfully ignores board" do
      board = create(:board)
      user = create(:user)
      login_as(user)
      expect(board).not_to be_ignored_by(user)
      post :mark, board_id: board.id, commit: "Hide from Unread"
      expect(Board.find(board.id)).to be_ignored_by(user) # reload to reset cached @view
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("#{board.name} hidden from this page.")
    end
  end
end
