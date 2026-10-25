RSpec.describe Api::V1::IndexesController do
  describe "GET index" do
    let(:result_ids) { response.parsed_body['results'].pluck('id') }

    it "works logged out", :show_in_doc do
      index = create(:index, description: 'An index')
      create(:index_post, index: index)
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(1)
      result = response.parsed_body['results'][0]
      expect(result['id']).to eq(index.id)
      expect(result['name']).to eq(index.name)
      expect(result['description']).to eq('An index')
      expect(result['privacy']).to eq('public')
      expect(result['authors_locked']).to be(true)
      expect(result['user']).to eq({ 'id' => index.user.id, 'username' => index.user.username })
      expect(result['num_posts']).to eq(1)
    end

    it "orders indexes by ID" do
      indexes = create_list(:index, 3)
      get :index
      expect(result_ids).to eq(indexes.map(&:id))
    end

    it "hides non-public indexes when logged out" do
      public_index = create(:index)
      (Index.privacies.keys - ['public']).each { |privacy| create(:index, privacy: privacy) }
      get :index
      expect(result_ids).to eq([public_index.id])
    end

    it "shows indexes visible to a full user" do
      user = api_login
      visible = [:public, :registered, :full_accounts].map { |privacy| create(:index, privacy: privacy) }
      own = create(:index, user: user, privacy: :private)
      create(:index, privacy: :private)
      create(:index, privacy: :access_list)
      get :index
      expect(result_ids).to eq(visible.map(&:id) + [own.id])
    end

    it "shows indexes visible to a reader account" do
      api_login_as(create(:reader_user))
      visible = [:public, :registered].map { |privacy| create(:index, privacy: privacy) }
      create(:index, privacy: :full_accounts)
      create(:index, privacy: :private)
      get :index
      expect(result_ids).to eq(visible.map(&:id))
    end

    it "counts only posts visible to the user" do
      index = create(:index)
      create(:index_post, index: index)
      create(:index_post, index: index, post: create(:post, privacy: :private))
      create(:index_post, index: index, post: create(:post, board: create(:board, id: Board::ID_SITETESTING)))
      get :index
      expect(response.parsed_body['results'][0]['num_posts']).to eq(1)
    end

    it "counts private posts for their author" do
      index = create(:index)
      author = create(:user)
      create(:index_post, index: index, post: create(:post, user: author, privacy: :private))
      create(:index_post, index: index)
      api_login_as(author)
      get :index
      expect(response.parsed_body['results'][0]['num_posts']).to eq(2)
    end

    it "does not count posts hidden by blocks" do
      user = api_login
      blocked_user = create(:user)
      create(:block, blocking_user: user, blocked_user: blocked_user, hide_them: :posts)
      index = create(:index)
      create(:index_post, index: index, post: create(:post, user: blocked_user, authors_locked: true))
      create(:index_post, index: index)
      get :index
      expect(response.parsed_body['results'][0]['num_posts']).to eq(1)
    end

    it "returns zero posts for an empty index" do
      create(:index)
      get :index
      expect(response.parsed_body['results'][0]['num_posts']).to eq(0)
    end

    it "paginates results" do
      create_list(:index, 26)
      get :index
      expect(response.parsed_body['results'].size).to eq(25)
      expect(response.headers['Total'].to_i).to eq(26)
    end

    it "paginates results on additional pages" do
      create_list(:index, 27)
      get :index, params: { page: 2 }
      expect(response.parsed_body['results'].size).to eq(2)
    end

    it "counts only visible indexes in the pagination headers" do
      create(:index)
      create(:index, privacy: :private)
      get :index
      expect(response.headers['Total'].to_i).to eq(1)
    end

    it "raises error on invalid page", :show_in_doc do
      get :index, params: { page: 'b' }
      expect(response).to have_http_status(422)
    end
  end

  describe "GET show" do
    let(:index) { create(:index) }

    it "requires valid index", :show_in_doc do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Index could not be found.")
    end

    it "requires visible index", :show_in_doc do
      private_index = create(:index, privacy: :private)
      get :show, params: { id: private_index.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "requires visible index for other users" do
      private_index = create(:index, privacy: :private)
      api_login
      get :show, params: { id: private_index.id }
      expect(response).to have_http_status(403)
    end

    it "requires full account for full-accounts index" do
      full_index = create(:index, privacy: :full_accounts)
      api_login_as(create(:reader_user))
      get :show, params: { id: full_index.id }
      expect(response).to have_http_status(403)
    end

    it "works for the owner of a private index" do
      private_index = create(:index, privacy: :private)
      api_login_as(private_index.user)
      get :show, params: { id: private_index.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(private_index.id)
    end

    it "works for reader account" do
      api_login_as(create(:reader_user))
      get :show, params: { id: index.id }
      expect(response).to have_http_status(200)
    end

    it "works for an empty index" do
      get :show, params: { id: index.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(index.id)
      expect(response.parsed_body['name']).to eq(index.name)
      expect(response.parsed_body['user']['id']).to eq(index.user_id)
      expect(response.parsed_body['index_sections']).to eq([])
      expect(response.parsed_body['unsectioned_posts']).to eq([])
    end

    it "returns sections and posts in order", :show_in_doc do
      section1 = create(:index_section, index: index, description: 'First section')
      section2 = create(:index_section, index: index)
      empty_section = create(:index_section, index: index)
      section1.update!(section_order: 1)
      section2.update!(section_order: 0)
      empty_section.update!(section_order: 2)

      board = create(:board)
      post = Timecop.freeze(DateTime.new(2019, 1, 2, 3, 4, 5).utc) do
        create(:post, board: board, section: create(:board_section, board: board), num_replies: 2)
      end
      s1_first = create(:index_post, index: index, index_section: section1)
      s1_second = create(:index_post, index: index, index_section: section1, post: post, description: 'A note')
      s2_post = create(:index_post, index: index, index_section: section2)
      unsectioned1 = create(:index_post, index: index)
      unsectioned2 = create(:index_post, index: index)
      s1_first.update!(section_order: 1)
      s1_second.update!(section_order: 0)
      unsectioned1.update!(section_order: 1)
      unsectioned2.update!(section_order: 0)

      get :show, params: { id: index.id }
      expect(response).to have_http_status(200)

      sections = response.parsed_body['index_sections']
      expect(sections.pluck('id')).to eq([section2.id, section1.id, empty_section.id])
      expect(sections.pluck('order')).to eq([0, 1, 2])
      expect(sections[1]['name']).to eq(section1.name)
      expect(sections[1]['description']).to eq('First section')
      expect(sections[0]['posts'].pluck('id')).to eq([s2_post.post_id])
      expect(sections[1]['posts'].pluck('id')).to eq([s1_second.post_id, s1_first.post_id])
      expect(sections[2]['posts']).to eq([])

      post_json = sections[1]['posts'][0]
      expect(post_json['subject']).to eq(post.subject)
      expect(post_json['board']['id']).to eq(board.id)
      expect(post_json['section']['id']).to eq(post.section_id)
      expect(post_json['authors'].pluck('id')).to eq([post.user_id])
      expect(post_json['num_replies']).to eq(2)
      expect(post_json['tagged_at']).to be_the_same_time_as(post.reload.tagged_at)
      expect(post_json['index_post_id']).to eq(s1_second.id)
      expect(post_json['index_description']).to eq('A note')

      expect(response.parsed_body['unsectioned_posts'].pluck('id')).to eq([unsectioned2.post_id, unsectioned1.post_id])
    end

    it "hides posts the user cannot see" do
      section = create(:index_section, index: index)
      visible = create(:index_post, index: index, index_section: section)
      create(:index_post, index: index, index_section: section, post: create(:post, privacy: :private))
      create(:index_post, index: index, post: create(:post, privacy: :registered))
      create(:index_post, index: index, post: create(:post, board: create(:board, id: Board::ID_SITETESTING)))
      get :show, params: { id: index.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['index_sections'][0]['posts'].pluck('id')).to eq([visible.post_id])
      expect(response.parsed_body['unsectioned_posts']).to eq([])
    end

    it "shows private posts to their author" do
      author = create(:user)
      private_post = create(:index_post, index: index, post: create(:post, user: author, privacy: :private))
      api_login_as(author)
      get :show, params: { id: index.id }
      expect(response.parsed_body['unsectioned_posts'].pluck('id')).to eq([private_post.post_id])
    end

    it "shows access-listed posts to viewers" do
      viewer = create(:user)
      listed = create(:post, privacy: :access_list)
      PostViewer.create!(post: listed, user: viewer)
      create(:index_post, index: index, post: listed)
      create(:index_post, index: index, post: create(:post, privacy: :access_list))
      api_login_as(viewer)
      get :show, params: { id: index.id }
      expect(response.parsed_body['unsectioned_posts'].pluck('id')).to eq([listed.id])
    end

    it "hides posts hidden by blocks" do
      user = api_login
      blocked_user = create(:user)
      create(:block, blocking_user: user, blocked_user: blocked_user, hide_them: :posts)
      create(:index_post, index: index, post: create(:post, user: blocked_user, authors_locked: true))
      visible = create(:index_post, index: index)
      get :show, params: { id: index.id }
      expect(response.parsed_body['unsectioned_posts'].pluck('id')).to eq([visible.post_id])
    end

    it "hides posts from users who block the caller" do
      user = api_login
      blocking_user = create(:user)
      create(:block, blocking_user: blocking_user, blocked_user: user, hide_me: :posts)
      create(:index_post, index: index, post: create(:post, user: blocking_user, authors_locked: true))
      visible = create(:index_post, index: index)
      get :show, params: { id: index.id }
      expect(response.parsed_body['unsectioned_posts'].pluck('id')).to eq([visible.post_id])
    end

    it "raises error on invalid id" do
      get :show, params: { id: 'b' }
      expect(response).to have_http_status(422)
    end
  end
end
