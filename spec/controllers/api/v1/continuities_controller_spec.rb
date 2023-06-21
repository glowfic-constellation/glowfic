RSpec.describe Api::V1::ContinuitiesController do
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
      api_login
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
      api_login
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

  describe 'GET posts' do
    it 'requires a valid board', show_in_doc: true do
      get :posts, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Continuity could not be found.")
    end

    it 'filters non-public posts' do
      public_post = create(:post, privacy: :public)
      create(:post, privacy: :private, board: public_post.board)
      get :posts, params: { id: public_post.board_id }
      expect(response).to have_http_status(200)
      expect(response.json['results'].size).to eq(1)
      expect(response.json['results'][0]['id']).to eq(public_post.id)
    end

    it 'returns only the correct posts', show_in_doc: true do
      board = create(:board)
      user_post = Timecop.freeze(DateTime.new(2019, 1, 2, 3, 4, 5).utc) do
        create(:post, board: board, section: create(:board_section, board: board))
      end
      create(:post, board: create(:board))
      get :posts, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.json['results'].size).to eq(1)
      expect(response.json['results'][0]['id']).to eq(user_post.id)
      expect(response.json['results'][0]['board']['id']).to eq(user_post.board_id)
      expect(response.json['results'][0]['section']['id']).to eq(user_post.section_id)
    end

    it 'paginates results' do
      board = create(:board)
      create_list(:post, 26, board: board)
      get :posts, params: { id: board.id }
      expect(response.json['results'].size).to eq(25)
    end

    it 'paginates results on additional pages' do
      board = create(:board)
      create_list(:post, 27, board: board)
      get :posts, params: { id: board.id, page: 2 }
      expect(response.json['results'].size).to eq(2)
    end
  end
end
