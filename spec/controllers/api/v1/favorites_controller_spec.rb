RSpec.describe Api::V1::FavoritesController do
  describe "GET index" do
    it "requires login", :show_in_doc do
      get :index
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "returns empty with no favorites" do
      api_login
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['favorites']).to eq([])
    end

    it "returns the user's favorites of each type", :show_in_doc do
      user = api_login
      favorited_user = create(:user)
      board = create(:board)
      favorited_post = create(:post)
      user_fav = create(:favorite, user: user, favorite: favorited_user)
      board_fav = create(:favorite, user: user, favorite: board)
      post_fav = create(:favorite, user: user, favorite: favorited_post)
      create(:favorite, favorite: create(:post)) # another user's favorite

      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['favorites']).to eq([
        {
          'id'            => board_fav.id,
          'favorite_type' => 'Board',
          'favorite_id'   => board.id,
          'favorite'      => { 'id' => board.id, 'name' => board.name },
        },
        {
          'id'            => post_fav.id,
          'favorite_type' => 'Post',
          'favorite_id'   => favorited_post.id,
          'favorite'      => { 'id' => favorited_post.id, 'subject' => favorited_post.subject },
        },
        {
          'id'            => user_fav.id,
          'favorite_type' => 'User',
          'favorite_id'   => favorited_user.id,
          'favorite'      => { 'id' => favorited_user.id, 'username' => favorited_user.username },
        },
      ])
    end

    it "hides the names of deleted users" do
      user = api_login
      favorited_user = create(:user)
      create(:favorite, user: user, favorite: favorited_user)
      favorited_user.update!(deleted: true)

      get :index
      expect(response.parsed_body['favorites'][0]['favorite']).to eq({ 'id' => favorited_user.id, 'username' => '(deleted user)' })
    end

    it "leaves out favorited posts the user cannot view" do
      user = api_login
      visible = create(:post)
      hidden = create(:post)
      blocked = create(:post, authors_locked: true)
      create(:favorite, user: user, favorite: visible)
      create(:favorite, user: user, favorite: hidden)
      create(:favorite, user: user, favorite: blocked)
      hidden.update!(privacy: :private)
      create(:block, blocking_user: blocked.user, blocked_user: user, hide_me: :posts)

      get :index
      expect(response.parsed_body['favorites'].pluck('favorite_id')).to eq([visible.id])
      expect(response.headers['Total'].to_i).to eq(1)
    end

    it "shows favorited access-listed posts to viewers" do
      user = api_login
      access_post = create(:post, privacy: :access_list, viewers: [user])
      create(:favorite, user: user, favorite: access_post)

      get :index
      expect(response.parsed_body['favorites'].pluck('favorite_id')).to eq([access_post.id])
    end

    it "paginates" do
      user = api_login
      create_list(:post, 26).each { |favorited_post| create(:favorite, user: user, favorite: favorited_post) }

      get :index, params: { page: 2 }
      expect(response.parsed_body['favorites'].size).to eq(1)
      expect(response.headers['Total'].to_i).to eq(26)
    end
  end
end
