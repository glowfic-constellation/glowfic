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
      board = create(:board)
      posts = create_list(:post, 2, board: board)
      create(:post)
      get :search, params: { commit: true, board_id: board.id }
      expect(assigns(:search_results)).to match_array(posts)
    end

    it "filters by setting" do
      setting = create(:setting)
      post = create(:post, settings: [setting])
      create(:post)
      get :search, params: { commit: true, setting_id: setting.id }
      expect(assigns(:search_results)).to match_array([post])
    end

    context "filters by subject" do
      let!(:post1) { create(:post, subject: 'contains stars') }
      let!(:post2) { create(:post, subject: 'contains Stars') }

      before(:each) { create(:post, subject: 'unrelated') }

      it "successfully" do
        get :search, params: { commit: true, subject: 'stars' }
        expect(assigns(:search_results)).to match_array([post1, post2])
      end

      it "acronym" do
        post3 = create(:post, subject: 'Case starlight')
        get :search, params: { commit: true, subject: 'cs', abbrev: true }
        expect(assigns(:search_results)).to match_array([post1, post2, post3])
      end

      it "exact match" do
        skip "TODO not yet implemented"
      end
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

    context "filters by authors" do
      let(:author1) { create(:user) }
      let(:author2) { create(:user) }
      let!(:post1) { create(:post, user: author1) } # a1 only, post only
      let!(:post2) { create(:post) } # a2 only, reply only
      let!(:post3) { create(:post, user: author1) } # both authors, a1 post only
      let!(:post4) { create(:post) } # both authors, replies only

      before(:each) do
        create(:post)
        create(:reply, post: post2, user: author2)
        create(:reply, post: post3, user: author2)
        create(:reply, post: post4, user: author1)
        create(:reply, post: post4, user: author2)
      end

      it "one author" do
        get :search, params: { commit: true, author_id: [author1.id] }
        expect(assigns(:search_results)).to match_array([post1, post3, post4])
      end

      it "multiple authors" do
        get :search, params: { commit: true, author_id: [author1.id, author2.id] }
        expect(assigns(:search_results)).to match_array([post3, post4])
      end
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
      get :search, params: { commit: true, completed: true }
      expect(assigns(:search_results)).to match_array(post)
    end

    it "sorts posts by tagged_at" do
      posts = create_list(:post, 4)
      create(:reply, post: posts[2])
      create(:reply, post: posts[1])
      get :search, params: { commit: true }
      expect(assigns(:search_results)).to eq([posts[1], posts[2], posts[3], posts[0]])
    end

    context "when logged out" do
      it_behaves_like "logged out post list"
    end

    context "when logged in" do
      it_behaves_like "logged in post list"
    end

    context "with hide_from_all" do
      let(:viewer) { create(:user) }
      let(:ignored_board) { create(:board) }
      let!(:ignored_post) { create(:post) }
      let!(:ignored_board_post) { create(:post, board: ignored_board) }
      let!(:normal_post) { create(:post) }

      before(:each) do
        login_as(viewer)
        ignored_post.ignore(viewer)
        ignored_board.ignore(viewer)
      end

      it "does not hide ignored posts when hide_from_all is disabled" do
        get :search, params: { commit: true }
        expect(assigns(:search_results).map(&:id)).to match_array([ignored_post.id, ignored_board_post.id, normal_post.id])
      end

      it "hides ignored posts by default when hide_from_all is enabled" do
        viewer.update!(hide_from_all: true)
        get :search, params: { commit: true }
        expect(assigns(:search_results).map(&:id)).to eq([normal_post.id])
      end

      it "shows ignored posts when checkbox is unchecked with hide_from_all enabled" do
        viewer.update!(hide_from_all: true)
        get :search, params: { commit: true, hide_ignored: '0' }
        expect(assigns(:search_results).map(&:id)).to match_array([ignored_post.id, ignored_board_post.id, normal_post.id])
      end
    end
  end
end
