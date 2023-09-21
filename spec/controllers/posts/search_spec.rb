RSpec.describe PostsController, 'GET search' do
  context "no search" do
    it "works logged out" do
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Posts')
      expect(assigns(:search_results)).to be_nil
    end

    it "works logged in" do
      login
      get :search
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('Search Posts')
      expect(assigns(:search_results)).to be_nil
    end

    it "works for reader account" do
      login_as(create(:reader_user))
      get :search
      expect(response).to have_http_status(200)
    end
  end

  context "searching" do
    let(:controller_action) { "search" }
    let(:params) { { commit: true } }
    let(:assign_variable) { :search_results }

    it "finds all when no arguments given" do
      create_list(:post, 4)
      get :search, params: { commit: true }
      expect(assigns(:search_results)).to match_array(Post.all)
    end

    it "filters by continuity" do
      post = create(:post)
      post2 = create(:post, continuity: post.continuity)
      create(:post)
      get :search, params: { commit: true, board_id: post.board_id }
      expect(assigns(:search_results)).to match_array([post, post2])
    end

    it "filters by setting" do
      setting = create(:setting)
      post = create(:post)
      post.settings << setting
      create(:post)
      get :search, params: { commit: true, setting_id: setting.id }
      expect(assigns(:search_results)).to match_array([post])
    end

    it "filters by subject" do
      post1 = create(:post, subject: 'contains stars')
      post2 = create(:post, subject: 'contains Stars cased')
      create(:post, subject: 'unrelated')
      get :search, params: { commit: true, subject: 'stars' }
      expect(assigns(:search_results)).to match_array([post1, post2])
    end

    it "filters by subject acronym" do
      post1 = create(:post, subject: 'contains stars')
      post2 = create(:post, subject: 'contains Stars')
      post3 = create(:post, subject: 'Case starlight')
      create(:post, subject: 'unrelated')
      get :search, params: { commit: true, subject: 'cs', abbrev: true }
      expect(assigns(:search_results)).to match_array([post1, post2, post3])
    end

    it "does not mix up subject with content" do
      create(:post, subject: 'unrelated', content: 'contains stars')
      get :search, params: { commit: true, subject: 'stars' }
      expect(assigns(:search_results)).to be_empty
    end

    it "restricts to visible posts" do
      create(:post, subject: 'contains stars', privacy: :private)
      post = create(:post, subject: 'visible contains stars')
      get :search, params: { commit: true, subject: 'stars' }
      expect(assigns(:search_results)).to match_array([post])
    end

    it "filters by exact match subject" do
      skip "TODO not yet implemented"
    end

    it "filters by authors" do
      posts = Array.new(4) { create(:post) }
      filtered_post = posts.last
      first_post = posts.first
      create(:reply, post: first_post, user: filtered_post.user)
      get :search, params: { commit: true, author_id: [filtered_post.user_id] }
      expect(assigns(:search_results)).to match_array([filtered_post, first_post])
    end

    it "filters by multiple authors" do
      author1 = create(:user)
      author2 = create(:user)
      nonauthor = create(:user)

      found_posts = []
      create(:post, user: author1) # one author but not the other, post
      post = create(:post, user: nonauthor) # one author but not the other, reply
      create(:reply, user: author2, post: post)

      post = create(:post, user: author1) # both authors, one post only
      create(:reply, post: post, user: author2)
      found_posts << post

      post = create(:post, user: nonauthor) # both authors, replies only
      create(:reply, post: post, user: author1)
      create(:reply, post: post, user: author2)
      found_posts << post

      get :search, params: { commit: true, author_id: [author1.id, author2.id] }
      expect(assigns(:search_results)).to match_array(found_posts)
    end

    it "filters by characters" do
      create(:reply, with_character: true)
      reply = create(:reply, with_character: true)
      post = create(:post, character: reply.character, user: reply.user)
      get :search, params: { commit: true, character_id: reply.character_id }
      expect(assigns(:search_results)).to match_array([reply.post, post])
    end

    it "filters by completed" do
      create(:post)
      post = create(:post, status: :complete)
      get :search, params: { commit: true, completed: '1' }
      expect(assigns(:search_results)).to match_array(post)
    end

    it "sorts posts by tagged_at" do
      posts = Array.new(4) { create(:post) }
      create(:reply, post: posts[2])
      create(:reply, post: posts[1])
      get :search, params: { commit: true }
      expect(assigns(:search_results)).to eq([posts[1], posts[2], posts[3], posts[0]])
    end

    context "when logged out" do
      include_examples "logged out post list"
    end

    context "when logged in" do
      include_examples "logged in post list"
    end
  end
end
