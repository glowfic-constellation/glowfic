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

    it "requires valid section" do
      board = create(:board)
      login_as(board.creator)
      post :create, board_section: {board_id: board.id}
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Section could not be created.")
    end

    it "succeeds" do
      board = create(:board)
      login_as(board.creator)
      section_name = 'ValidSection'
      post :create, board_section: {board_id: board.id, name: section_name}
      expect(response).to redirect_to(edit_board_url(board))
      expect(flash[:success]).to eq("New #{board.name} section #{section_name} has been successfully created.")
      expect(assigns(:board_section).name).to eq(section_name)
    end
  end

  describe "GET show" do
    it "requires valid section" do
      get :show, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "does not require login" do
      section = create(:board_section)
      posts = 2.times.collect do create(:post, board: section.board, section: section) end
      create(:post)
      create(:post, board: section.board)
      get :show, id: section.id
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to match_array(posts)
    end

    it "works with login" do
      section = create(:board_section)
      posts = 2.times.collect do create(:post, board: section.board, section: section) end
      create(:post)
      create(:post, board: section.board)
      get :show, id: section.id
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq(section.name)
      expect(assigns(:posts)).to match_array(posts)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid section" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "requires permission" do
      section = create(:board_section)
      login
      get :edit, id: section.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works" do
      section = create(:board_section)
      login_as(section.board.creator)
      get :edit, id: section.id
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq("Edit #{section.name}")
      expect(assigns(:board_section)).to eq(section)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires board permission" do
      user = create(:user)
      login_as(user)
      board_section = create(:board_section)
      expect(board_section.board).not_to be_editable_by(user)

      put :update, id: board_section.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "requires valid params" do
      board_section = create(:board_section)
      login_as(board_section.board.creator)
      put :update, id: board_section.id, board_section: {name: ''}
      expect(response).to have_http_status(200)
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Section could not be updated.")
    end

    it "succeeds" do
      board_section = create(:board_section, name: 'TestSection1')
      login_as(board_section.board.creator)
      section_name = 'TestSection2'
      put :update, id: board_section.id, board_section: {name: section_name}
      expect(response).to redirect_to(board_section_path(board_section))
      expect(board_section.reload.name).to eq(section_name)
      expect(flash[:success]).to eq("#{section_name} has been successfully updated.")
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid section" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Section not found.")
    end

    it "requires permission" do
      section = create(:board_section)
      login
      delete :destroy, id: section.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to edit this continuity.")
    end

    it "works" do
      section = create(:board_section)
      login_as(section.board.creator)
      delete :destroy, id: section.id
      expect(response).to redirect_to(edit_board_url(section.board))
      expect(flash[:success]).to eq("Section deleted.")
      expect(BoardSection.find_by_id(section.id)).to be_nil
    end
  end
end
