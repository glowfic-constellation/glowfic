RSpec.describe Api::V1::UsersController do
  describe "GET index" do
    def create_search_users
      create(:user, username: 'baa', moiety: '123456', moiety_name: 'Test') # firstuser
      create(:user, username: 'aba') # miduser
      create(:user, username: 'aab') # enduser
      create(:user, username: 'aaa') # notuser
      User.find_each do |user|
        create(:user, username: user.username.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_users
      api_login
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].count).to eq(9)
    end

    it "works logged out", :show_in_doc do
      create_search_users
      get :index, params: { q: 'b' }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].count).to eq(2)
    end

    it "raises error on invalid page", :show_in_doc do
      get :index, params: { page: 'b' }
      expect(response).to have_http_status(422)
    end

    it "supports exact match", :show_in_doc do
      create(:user, username: 'alicorn')
      create(:user, username: 'ali')
      get :index, params: { q: 'ali', match: 'exact' }
      expect(response.parsed_body['results'].count).to eq(1)
    end

    it "handles hiding unblockable users" do
      user = create(:user)
      api_login_as(user)
      create_list(:block, 2, blocking_user: user)
      create_list(:user, 3)
      get :index, params: { hide_unblockable: true }
      expect(response.parsed_body['results'].count).to eq(3)
    end

    it "does not hide unblockable users unless that parameter is sent" do
      user = create(:user)
      api_login_as(user)
      create_list(:block, 2, blocking_user: user)
      create_list(:user, 3)
      get :index
      expect(response.parsed_body['results'].count).to eq(6)
    end

    it "does not return deleted users" do
      create(:user, deleted: true)
      create(:user)
      get :index
      expect(response.parsed_body['results'].count).to eq(1)
    end

    it "shows moieties appropriately" do
      create(:user, username: 'Throne3d', moiety: '960018', moiety_name: 'Carmine')
      create(:user, username: 'anon')
      get :index
      expect(response.parsed_body['results']).to contain_exactly(
        a_collection_including(
          'username'    => 'Throne3d',
          'moiety'      => '960018',
          'moiety_name' => 'Carmine',
        ),
        a_collection_including(
          'username'    => 'anon',
          'moiety'      => nil,
          'moiety_name' => nil,
        ),
      )
    end
  end

  describe 'GET posts' do
    it 'requires a valid user', :show_in_doc do
      get :posts, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("User could not be found.")
    end

    it 'filters non-public posts' do
      user = create(:user)
      public_post = create(:post, privacy: :public, user: user)
      create(:post, privacy: :private, user: user)
      get :posts, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(1)
      expect(response.parsed_body['results'][0]['id']).to eq(public_post.id)
    end

    it 'returns only the correct posts', :show_in_doc do
      user = create(:user)
      board = create(:board)
      user_post = create(:post, user: user, board: board, section: create(:board_section, board: board))
      create(:post, user: create(:user))
      get :posts, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(1)
      expect(response.parsed_body['results'][0]['id']).to eq(user_post.id)
      expect(response.parsed_body['results'][0]['board']['id']).to eq(user_post.board_id)
      expect(response.parsed_body['results'][0]['section']['id']).to eq(user_post.section_id)
    end

    it 'paginates results' do
      user = create(:user)
      create_list(:post, 26, user: user)
      get :posts, params: { id: user.id }
      expect(response.parsed_body['results'].size).to eq(25)
    end

    it 'paginates results on additional pages' do
      user = create(:user)
      create_list(:post, 27, user: user)
      get :posts, params: { id: user.id, page: 2 }
      expect(response.parsed_body['results'].size).to eq(2)
    end
  end

  describe 'GET bookmarks' do
    it 'requires a valid user', :show_in_doc do
      get :bookmarks, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("User could not be found.")
    end

    it "returns empty with private bookmarks", :show_in_doc do
      user = create(:user)
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(0)
    end

    it "succeeds with public bookmarks", :show_in_doc do
      user = create(:user, public_bookmarks: true)
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(0)
    end

    it "succeeds with own bookmarks", :show_in_doc do
      user = api_login
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(0)
    end

    it "filters non-visible bookmarks", :show_in_doc do
      user = create(:user, public_bookmarks: true)
      bookmarks = create_list(:bookmark, 2, user: user)
      bookmarks[0].post.update!(privacy: :private)
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(1)
      expect(response.parsed_body['bookmarks'][0]['id']).to eq(bookmarks[1].id)
    end

    it "filters post", :show_in_doc do
      user = create(:user, public_bookmarks: true)
      bookmarks = create_list(:bookmark, 3, user: user)
      get :bookmarks, params: { id: user.id, post_id: bookmarks[2].post_id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(1)
      expect(response.parsed_body['bookmarks'][0]['id']).to eq(bookmarks[2].id)
    end

    it "returns only the user's bookmarks", :show_in_doc do
      user = create(:user, public_bookmarks: true)
      bookmark = create(:bookmark, user: user)
      create(:bookmark, user: create(:user, public_bookmarks: true))
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(1)
      expect(response.parsed_body['bookmarks'][0]['id']).to eq(bookmark.id)
    end

    it 'paginates results' do
      user = create(:user, public_bookmarks: true)
      create_list(:bookmark, 26, user: user)
      get :bookmarks, params: { id: user.id }
      expect(response.parsed_body['bookmarks'].size).to eq(25)
    end

    it 'paginates results on additional pages' do
      user = create(:user, public_bookmarks: true)
      create_list(:bookmark, 27, user: user)
      get :bookmarks, params: { id: user.id, page: 2 }
      expect(response.parsed_body['bookmarks'].size).to eq(2)
    end
  end
end
