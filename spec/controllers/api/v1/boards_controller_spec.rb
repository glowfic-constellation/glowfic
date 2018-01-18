require "spec_helper"

RSpec.describe Api::V1::BoardsController do
  describe "GET index" do
    def create_search_boards
      create(:board, name: 'baa') # firstuser
      create(:board, name: 'aba') # miduser
      create(:board, name: 'aab') # enduser
      create(:board, name: 'aaa') # notuser
      Board.all.each do |board|
        create(:board, name: board.name.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_boards
      login
      get :index
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(8)
    end

    it "works logged out", show_in_doc: true do
      create_search_boards
      get :index, params: { q: 'b' }
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(2)
    end

    it "raises error on invalid page", show_in_doc: true do
      get :index, params: { page: 'b' }
      expect(response).to have_http_status(422)
    end
  end

  describe "GET show" do
    it "requires valid board", :show_in_doc do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Continuity could not be found.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(board.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['id']).to eq(section2.id)
    end

    it "succeeds for logged in users with valid board" do
      login
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(board.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['id']).to eq(section2.id)
    end

    it "orders sections by section_order", :show_in_doc do
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      section1.section_order = 1
      section1.save!
      section2.section_order = 0
      section2.save!
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(board.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section2.id)
      expect(response.json['board_sections'][0]['order']).to eq(0)
      expect(response.json['board_sections'][1]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['order']).to eq(1)
    end
  end
end
