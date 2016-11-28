require "spec_helper"

RSpec.describe BoardSectionsController do
  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      user = create(:user)
      board = create(:board)
      expect(board.editable_by?(user)).to eq(false)
      login_as(user)

      get :new, board_id: board.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works with board_id" do
      board = create(:board)
      login_as(board.creator)
      get :new, board_id: board.id
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end

    it "works without board_id" do
      login
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Section")
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      user = create(:user)
      board = create(:board)
      expect(board.editable_by?(user)).to eq(false)
      login_as(user)

      post :create, board_section: {board_id: board.id}
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "GET show" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip
    end
  end
end
