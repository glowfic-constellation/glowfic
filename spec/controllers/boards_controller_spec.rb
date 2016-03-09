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
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end

    it "sets the correct cowriters" do
      skip
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      skip
    end

    it "successfully makes a board" do
      skip
    end
  end

  describe "GET show" do
    it "requires valid board" do
      get :show, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(boards_url)
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
      skip
    end

    it "orders the posts by updated_at" do
      skip
    end

    it "does not fetch posts the user cannot see" do
      skip
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
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid board id" do
      skip
    end

    it "requires valid action" do
      skip
    end

    it "successfully marks board read" do
      skip
    end

    it "successfully ignores board" do
      skip
    end
  end
end
