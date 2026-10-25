RSpec.describe Api::V1::BoardsController do
  describe "GET index" do
    def create_search_boards
      create(:board, name: 'baa') # firstuser
      create(:board, name: 'aba') # miduser
      create(:board, name: 'aab') # enduser
      create(:board, name: 'aaa') # notuser
      Board.find_each do |board|
        create(:board, name: board.name.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_boards
      api_login
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].count).to eq(8)
    end

    it "works logged out", :show_in_doc do
      create_search_boards
      get :index, params: { q: 'b' }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].count).to eq(2)
    end

    it "raises error on invalid page", :show_in_doc do
      get :index, params: { page: 'b' }
      expect(response).to have_http_status(422)
    end
  end

  describe "GET show" do
    it "requires valid board", :show_in_doc do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Continuity could not be found.")
    end

    it "succeeds with valid board" do
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(board.id)
      expect(response.parsed_body['board_sections'].size).to eq(2)
      expect(response.parsed_body['board_sections'][0]['id']).to eq(section1.id)
      expect(response.parsed_body['board_sections'][1]['id']).to eq(section2.id)
    end

    it "succeeds for logged in users with valid board" do
      api_login
      board = create(:board)
      section1 = create(:board_section, board: board)
      section2 = create(:board_section, board: board)
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(board.id)
      expect(response.parsed_body['board_sections'].size).to eq(2)
      expect(response.parsed_body['board_sections'][0]['id']).to eq(section1.id)
      expect(response.parsed_body['board_sections'][1]['id']).to eq(section2.id)
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
      expect(response.parsed_body['id']).to eq(board.id)
      expect(response.parsed_body['board_sections'].size).to eq(2)
      expect(response.parsed_body['board_sections'][0]['id']).to eq(section2.id)
      expect(response.parsed_body['board_sections'][0]['order']).to eq(0)
      expect(response.parsed_body['board_sections'][1]['id']).to eq(section1.id)
      expect(response.parsed_body['board_sections'][1]['order']).to eq(1)
    end

    it "shows that an open continuity with no sections is unordered" do
      board = create(:board)
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['authors_locked']).to be(false)
      expect(response.parsed_body['ordered']).to be(false)
    end

    it "shows that a continuity with locked authors is ordered", :show_in_doc do
      board = create(:board, authors_locked: true)
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['authors_locked']).to be(true)
      expect(response.parsed_body['ordered']).to be(true)
    end

    it "shows that a continuity with sections is ordered" do
      board = create(:board)
      create(:board_section, board: board)
      get :show, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['authors_locked']).to be(false)
      expect(response.parsed_body['ordered']).to be(true)
    end
  end

  describe 'GET posts' do
    it 'requires a valid board', :show_in_doc do
      get :posts, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Continuity could not be found.")
    end

    it 'filters non-public posts' do
      public_post = create(:post, privacy: :public)
      create(:post, privacy: :private, board: public_post.board)
      get :posts, params: { id: public_post.board_id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(1)
      expect(response.parsed_body['results'][0]['id']).to eq(public_post.id)
    end

    it 'returns only the correct posts', :show_in_doc do
      board = create(:board)
      user_post = Timecop.freeze(DateTime.new(2019, 1, 2, 3, 4, 5).utc) do
        create(:post, board: board, section: create(:board_section, board: board))
      end
      create(:post, board: create(:board))
      get :posts, params: { id: board.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(1)
      expect(response.parsed_body['results'][0]['id']).to eq(user_post.id)
      expect(response.parsed_body['results'][0]['board']['id']).to eq(user_post.board_id)
      expect(response.parsed_body['results'][0]['section']['id']).to eq(user_post.section_id)
    end

    it 'paginates results' do
      board = create(:board)
      create_list(:post, 26, board: board)
      get :posts, params: { id: board.id }
      expect(response.parsed_body['results'].size).to eq(25)
    end

    it 'paginates results on additional pages' do
      board = create(:board)
      create_list(:post, 27, board: board)
      get :posts, params: { id: board.id, page: 2 }
      expect(response.parsed_body['results'].size).to eq(2)
    end

    context "with order" do
      def result_ids
        response.parsed_body['results'].pluck('id')
      end

      def set_tagged_at(post, time)
        post.update_columns(tagged_at: time) # rubocop:disable Rails/SkipsModelValidations
      end

      def set_section_order(post, order)
        post.update_columns(section_order: order) # rubocop:disable Rails/SkipsModelValidations
      end

      it "orders by id by default" do
        board = create(:board)
        post1 = create(:post, board: board)
        post2 = create(:post, board: board)
        set_tagged_at(post1, 1.hour.ago)
        set_tagged_at(post2, 2.hours.ago)
        get :posts, params: { id: board.id }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([post1.id, post2.id])
      end

      it "orders by id when asked" do
        board = create(:board)
        post1 = create(:post, board: board)
        post2 = create(:post, board: board)
        set_tagged_at(post1, 1.hour.ago)
        set_tagged_at(post2, 2.hours.ago)
        get :posts, params: { id: board.id, order: 'id' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([post1.id, post2.id])
      end

      it "orders by tagged_at" do
        board = create(:board, authors_locked: true)
        post1 = create(:post, board: board)
        post2 = create(:post, board: board)
        post3 = create(:post, board: board)
        set_tagged_at(post1, 3.hours.ago)
        set_tagged_at(post2, 1.hour.ago)
        set_tagged_at(post3, 2.hours.ago)
        get :posts, params: { id: board.id, order: 'tagged_at' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([post2.id, post3.id, post1.id])
      end

      it "orders an unordered continuity newest first in board order" do
        board = create(:board)
        post1 = create(:post, board: board)
        post2 = create(:post, board: board)
        post3 = create(:post, board: board)
        set_tagged_at(post1, 2.hours.ago)
        set_tagged_at(post2, 3.hours.ago)
        set_tagged_at(post3, 1.hour.ago)
        get :posts, params: { id: board.id, order: 'board' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([post3.id, post1.id, post2.id])
      end

      it "orders a locked continuity with no sections by section order in board order" do
        board = create(:board, authors_locked: true)
        post1 = create(:post, board: board)
        post2 = create(:post, board: board)
        post3 = create(:post, board: board)
        set_section_order(post1, 2)
        set_section_order(post3, 0)
        set_section_order(post2, 1)
        set_tagged_at(post2, 1.hour.ago)
        get :posts, params: { id: board.id, order: 'board' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([post3.id, post2.id, post1.id])
      end

      it "orders a sectioned continuity like the HTML page in board order", :show_in_doc do
        board = create(:board)
        section1 = create(:board_section, board: board)
        section2 = create(:board_section, board: board)
        section1.update!(section_order: 1)
        section2.update!(section_order: 0)
        s1_post1 = create(:post, board: board, section: section1)
        s1_post2 = create(:post, board: board, section: section1)
        s2_post1 = create(:post, board: board, section: section2)
        s2_post2 = create(:post, board: board, section: section2)
        unsectioned1 = create(:post, board: board)
        unsectioned2 = create(:post, board: board)
        set_section_order(s1_post1, 1)
        set_section_order(s1_post2, 0)
        set_section_order(unsectioned1, 1)
        set_section_order(unsectioned2, 0)
        set_tagged_at(unsectioned1, 1.hour.from_now)

        get :posts, params: { id: board.id, order: 'board' }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq([s2_post1.id, s2_post2.id, s1_post2.id, s1_post1.id, unsectioned2.id, unsectioned1.id])

        results = response.parsed_body['results']
        expect(results[0]['section']).to eq({ 'id' => section2.id, 'name' => section2.name, 'order' => 0 })
        expect(results[0]['section_order']).to eq(0)
        expect(results[3]['section']['id']).to eq(section1.id)
        expect(results[3]['section']['order']).to eq(1)
        expect(results[3]['section_order']).to eq(1)
        expect(results[4]['section']).to be_nil
        expect(results[4]['section_order']).to eq(0)
      end

      it "breaks ties in section order by id in board order" do
        board = create(:board, authors_locked: true)
        post1 = create(:post, board: board)
        post2 = create(:post, board: board)
        post3 = create(:post, board: board)
        Post.where(id: [post1.id, post2.id, post3.id]).update_all(section_order: 0) # rubocop:disable Rails/SkipsModelValidations
        get :posts, params: { id: board.id, order: 'board' }
        expect(result_ids).to eq([post1.id, post2.id, post3.id])
      end

      it "paginates across a section boundary in board order" do
        board = create(:board)
        section1 = create(:board_section, board: board)
        section2 = create(:board_section, board: board)
        s1_posts = create_list(:post, 20, board: board, section: section1)
        s2_posts = create_list(:post, 10, board: board, section: section2)
        unsectioned = create_list(:post, 3, board: board)
        expected = (s1_posts + s2_posts + unsectioned).map(&:id)

        get :posts, params: { id: board.id, order: 'board' }
        expect(response).to have_http_status(200)
        expect(response.headers['Total'].to_i).to eq(33)
        expect(result_ids).to eq(expected[0...25])

        get :posts, params: { id: board.id, order: 'board', page: 2 }
        expect(response).to have_http_status(200)
        expect(result_ids).to eq(expected[25..])
      end

      it "rejects unknown orders", :show_in_doc do
        board = create(:board)
        get :posts, params: { id: board.id, order: 'subject' }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to include('order')
      end
    end

    context "with privacy in board order" do
      let(:author) { create(:user) }
      let(:board) { create(:board) }
      let(:section) { create(:board_section, board: board) }
      let!(:public_post) { create(:post, user: author, board: board, section: section) }
      let!(:private_post) { create(:post, user: author, board: board, section: section, privacy: :private) }
      let!(:access_post) { create(:post, user: author, board: board, privacy: :access_list) }

      def result_ids
        response.parsed_body['results'].pluck('id')
      end

      it "only shows public posts when logged out" do
        get :posts, params: { id: board.id, order: 'board' }
        expect(result_ids).to eq([public_post.id])
        expect(response.headers['Total'].to_i).to eq(1)
      end

      it "hides private and access-listed posts from other users" do
        api_login
        get :posts, params: { id: board.id, order: 'board' }
        expect(result_ids).to eq([public_post.id])
      end

      it "shows access-listed posts to viewers" do
        viewer = api_login
        PostViewer.create!(post: access_post, user: viewer)
        get :posts, params: { id: board.id, order: 'board' }
        expect(result_ids).to eq([public_post.id, access_post.id])
      end

      it "shows all posts to the author" do
        api_login_as(author)
        get :posts, params: { id: board.id, order: 'board' }
        expect(result_ids).to eq([public_post.id, private_post.id, access_post.id])
      end

      it "hides posts from users who block the viewer" do
        blocked_post = create(:post, board: board, section: section, authors_locked: true)
        viewer = api_login
        create(:block, blocking_user: blocked_post.user, blocked_user: viewer, hide_me: :posts)
        get :posts, params: { id: board.id, order: 'board' }
        expect(result_ids).to eq([public_post.id])
      end

      it "hides posts from users the viewer blocks" do
        hidden_post = create(:post, board: board, section: section, authors_locked: true)
        viewer = api_login
        create(:block, blocking_user: viewer, blocked_user: hidden_post.user, hide_them: :posts)
        get :posts, params: { id: board.id, order: 'board' }
        expect(result_ids).to eq([public_post.id])
      end

      it "hides posts from users the viewer blocks in the default order" do
        hidden_post = create(:post, board: board, authors_locked: true)
        viewer = api_login
        create(:block, blocking_user: viewer, blocked_user: hidden_post.user, hide_them: :posts)
        get :posts, params: { id: board.id }
        expect(result_ids).to eq([public_post.id])
      end
    end
  end
end
