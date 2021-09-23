RSpec.describe Api::V1::BoardsController do
  describe "GET index" do
    def create_search_continuities
      create(:continuity, name: 'baa')
      create(:continuity, name: 'aba')
      create(:continuity, name: 'aab')
      create(:continuity, name: 'aaa')
      Board.all.each do |continuity|
        create(:continuity, name: continuity.name.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_continuities
      api_login
      get :index
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(8)
    end

    it "works logged out", show_in_doc: true do
      create_search_continuities
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
    let (:continuity) { create(:continuity) }
    let!(:section1) { create(:board_section, board: continuity) }
    let!(:section2) { create(:board_section, board: continuity) }

    it "requires valid continuity", :show_in_doc do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Continuity could not be found.")
    end

    it "succeeds with valid continuity" do
      get :show, params: { id: continuity.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(continuity.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['id']).to eq(section2.id)
    end

    it "succeeds for logged in users with valid continuity" do
      api_login
      get :show, params: { id: continuity.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(continuity.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['id']).to eq(section2.id)
    end

    it "orders sections by section_order", :show_in_doc do
      section1.update!(section_order: 1)
      section2.update!(section_order: 0)
      get :show, params: { id: continuity.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(continuity.id)
      expect(response.json['board_sections'].size).to eq(2)
      expect(response.json['board_sections'][0]['id']).to eq(section2.id)
      expect(response.json['board_sections'][0]['order']).to eq(0)
      expect(response.json['board_sections'][1]['id']).to eq(section1.id)
      expect(response.json['board_sections'][1]['order']).to eq(1)
    end
  end

  describe 'GET posts' do
    let(:continuity) { create(:continuity) }

    it 'requires a valid continuity', show_in_doc: true do
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
      user_post = Timecop.freeze(DateTime.new(2019, 1, 2, 3, 4, 5).utc) do
        create(:post, board: continuity, section: create(:board_section, board: continuity))
      end
      create(:post, board: create(:continuity))
      get :posts, params: { id: continuity.id }
      expect(response).to have_http_status(200)
      expect(response.json['results'].size).to eq(1)
      expect(response.json['results'][0]['id']).to eq(user_post.id)
      expect(response.json['results'][0]['board']['id']).to eq(user_post.board_id)
      expect(response.json['results'][0]['section']['id']).to eq(user_post.section_id)
    end

    it 'paginates results' do
      create_list(:post, 26, board: continuity)
      get :posts, params: { id: continuity.id }
      expect(response.json['results'].size).to eq(25)
    end

    it 'paginates results on additional pages' do
      create_list(:post, 27, board: continuity)
      get :posts, params: { id: continuity.id, page: 2 }
      expect(response.json['results'].size).to eq(2)
    end
  end
end
