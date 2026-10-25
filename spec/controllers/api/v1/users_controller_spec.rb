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

    it "succeeds if bookmark is public", :show_in_doc do
      user = create(:user)
      create(:bookmark, user: user, public: true)
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(1)
    end

    it "succeeds if user bookmarks are public", :show_in_doc do
      user = create(:user, public_bookmarks: true)
      create(:bookmark, user: user)
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(1)
    end

    it "succeeds with own bookmarks", :show_in_doc do
      user = api_login
      create(:bookmark, user: user)
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(1)
    end

    it "filters non-public bookmarks", :show_in_doc do
      user = create(:user)
      bookmarks = create_list(:bookmark, 3, user: user)
      bookmarks[0].post.update!(privacy: :private)
      bookmarks[1].update!(public: true)
      get :bookmarks, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['bookmarks'].size).to eq(1)
      expect(response.parsed_body['bookmarks'][0]['id']).to eq(bookmarks[1].id)
    end

    it "Public bookmark doesn't override private post", :show_in_doc do
      user = create(:user)
      bookmarks = create_list(:bookmark, 2, user: user, public: true)
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

  describe 'GET galleries' do
    include QueryCountHelper

    it 'requires a valid user', :show_in_doc do
      get :galleries, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("User could not be found.")
    end

    it 'does not show deleted users' do
      user = create(:user, deleted: true)
      create(:gallery, user: user)
      get :galleries, params: { id: user.id }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'][0]['message']).to eq("User could not be found.")
    end

    it 'does not show read-only users' do
      user = create(:reader_user)
      get :galleries, params: { id: user.id }
      expect(response).to have_http_status(404)
    end

    it 'rejects invalid includes' do
      user = create(:user)
      get :galleries, params: { id: user.id, includes: ['characters'] }
      expect(response).to have_http_status(422)
    end

    it 'works for a user with no galleries' do
      user = create(:user)
      get :galleries, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['galleryless']).to eq({ 'id' => 0, 'name' => 'Galleryless', 'icon_count' => 0, 'gallery_groups' => [] })
      expect(response.parsed_body['results']).to eq([])
    end

    it "returns only the user's galleries ordered by name", :show_in_doc do
      user = create(:user)
      group = create(:gallery_group, name: 'Group')
      second = create(:gallery, user: user, name: 'b gallery', icon_count: 2, gallery_groups: [group])
      first = create(:gallery, user: user, name: 'A gallery')
      third = create(:gallery, user: user, name: 'c gallery', icon_count: 1)
      create(:gallery, name: 'a other gallery', icon_count: 1)
      create(:icon, user: user)
      create(:icon, user: user)
      create(:icon)

      get :galleries, params: { id: user.id }
      expect(response).to have_http_status(200)
      galleryless = response.parsed_body['galleryless']
      expect(galleryless).to eq({ 'id' => 0, 'name' => 'Galleryless', 'icon_count' => 2, 'gallery_groups' => [] })
      results = response.parsed_body['results']
      expect(results.pluck('id')).to eq([first.id, second.id, third.id])
      expect(results.pluck('name')).to eq(['A gallery', 'b gallery', 'c gallery'])
      expect(results.pluck('icon_count')).to eq([0, 2, 1])
      expect(results[1]['gallery_groups']).to eq([{ 'id' => group.id, 'text' => 'Group' }])
      expect(results[0]['gallery_groups']).to eq([])
      expect(results[0]).not_to have_key('icons')
      expect(galleryless).not_to have_key('icons')
    end

    it 'works logged in' do
      user = create(:user)
      gallery = create(:gallery, user: user, icon_count: 1)
      api_login
      get :galleries, params: { id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].pluck('id')).to eq([gallery.id])
    end

    it 'includes icons when requested', :show_in_doc do
      user = create(:user)
      gallery = create(:gallery, user: user)
      icon_b = create(:icon, user: user, keyword: 'b icon')
      icon_a = create(:icon, user: user, keyword: 'a icon')
      gallery.icons << icon_b
      gallery.icons << icon_a
      galleryless_icon = create(:icon, user: user, keyword: 'loose')

      get :galleries, params: { id: user.id, includes: ['icons'] }
      expect(response).to have_http_status(200)
      galleryless = response.parsed_body['galleryless']
      expect(galleryless['icons'].pluck('id')).to eq([galleryless_icon.id])
      expect(galleryless['icons'][0].keys).to match_array(['id', 'url', 'keyword'])
      results = response.parsed_body['results']
      expect(results[0]['icon_count']).to eq(2)
      expect(results[0]['icons'].pluck('id')).to eq([icon_a.id, icon_b.id])
      expect(results[0]['icons'][0]).to eq({ 'id' => icon_a.id, 'url' => icon_a.url, 'keyword' => 'a icon' })
    end

    it 'does not run a query per gallery' do
      user = create(:user)
      create(:gallery, user: user, icon_count: 1, gallery_groups: [create(:gallery_group)])
      get :galleries, params: { id: user.id, includes: ['icons'] }
      baseline = count_queries { get :galleries, params: { id: user.id, includes: ['icons'] } }
      create_list(:gallery, 3, user: user, icon_count: 2, gallery_groups: [create(:gallery_group)])
      expect(count_queries { get :galleries, params: { id: user.id, includes: ['icons'] } }).to eq(baseline)
    end

    it 'paginates results' do
      user = create(:user)
      create_list(:gallery, 26, user: user)
      get :galleries, params: { id: user.id }
      expect(response.parsed_body['results'].size).to eq(25)
      expect(response.headers['Total'].to_i).to eq(26)
    end

    it 'paginates results on additional pages' do
      user = create(:user)
      create_list(:gallery, 27, user: user)
      get :galleries, params: { id: user.id, page: 2 }
      expect(response.parsed_body['results'].size).to eq(2)
      expect(response.parsed_body['galleryless']['id']).to eq(0)
    end

    it 'supports per_page' do
      user = create(:user)
      create_list(:gallery, 3, user: user)
      get :galleries, params: { id: user.id, per_page: 2 }
      expect(response.parsed_body['results'].size).to eq(2)
      expect(response.headers['Per-Page'].to_i).to eq(2)
    end
  end
end
