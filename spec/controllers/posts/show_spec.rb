RSpec.describe PostsController, 'GET show' do
  let(:post) { create(:post) }
  let(:user) { create(:user) }

  it "does not require login" do
    get :show, params: { id: post.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')
  end

  it "works for reader account" do
    login_as(create(:reader_user))
    get :show, params: { id: post.id }
    expect(response).to have_http_status(200)
  end

  it "calculates OpenGraph meta" do
    user = create(:user, username: 'example user')
    board = create(:board, name: 'board')
    post = create(:post, subject: 'title', user: user, board: board)
    get :show, params: { id: post.id }

    meta_og = assigns(:meta_og)
    expect(meta_og[:url]).to eq(post_url(post))
    expect(meta_og[:title]).to eq('title · board')
    expect(meta_og[:description]).to eq('(example user – page 1 of 1)')
  end

  it "requires permission" do
    post = create(:post, privacy: :private)
    get :show, params: { id: post.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "works with login" do
    login
    get :show, params: { id: post.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')
  end

  context "marks read" do
    before(:each) { login_as(user) }

    it "successfully"

    it "multiple times" do
      get :show, params: { id: post.id }

      last_read = post.reload.last_read(user)
      expect(last_read).not_to be_nil

      Timecop.freeze(last_read + 1.second) do
        reply = create(:reply, post: post)
        expect(reply.created_at).not_to be_the_same_time_as(last_read)
        get :show, params: { id: post.id }
        cur_read = post.reload.last_read(user)
        expect(last_read).not_to be_the_same_time_as(cur_read)
        expect(last_read.to_i).to be < cur_read.to_i
      end
    end

    it "even if post is ignored" do
      post.ignore(user)
      expect(post.reload.first_unread_for(user)).to eq(post)

      get :show, params: { id: post.id }

      expect(post.reload.first_unread_for(user)).to be_nil
      last_read = post.last_read(user)

      Timecop.freeze(last_read + 1.second) do
        reply = create(:reply, post: post)
        expect(post.reload.first_unread_for(user)).to eq(reply)
        get :show, params: { id: post.id }
        expect(post.reload.first_unread_for(user)).to be_nil
      end
    end
  end

  context "invalid pages" do
    it "handles invalid pages" do
      get :show, params: { id: post.id, page: 'invalid' }
      expect(flash[:error]).to eq('Page not recognized, defaulting to page 1.')
      expect(assigns(:page)).to eq(1)
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end

    it "handles invalid unread page when logged out" do
      get :show, params: { id: post.id, page: 'unread' }
      expect(flash[:error]).to eq("You must be logged in to view unread posts.")
      expect(assigns(:page)).to eq(1)
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end

    it "handles pages outside range" do
      create_list(:reply, 5, post: post)
      get :show, params: { id: post.id, per_page: 1, page: 10 }
      expect(response).to redirect_to(post_url(post, page: 5, per_page: 1))
    end
  end

  context "handles page=last" do
    it "with replies" do
      create_list(:reply, 5, post: post)
      get :show, params: { id: post.id, per_page: 1, page: 'last' }
      expect(assigns(:page)).to eq(5)
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end

    it "with no replies" do
      get :show, params: { id: post.id, page: 'last' }
      expect(assigns(:page)).to eq(1)
      expect(response).to have_http_status(200)
      expect(response).to render_template(:show)
    end
  end

  it "calculates audits" do
    Reply.auditing_enabled = true
    Post.auditing_enabled = true

    replies = Audited.audit_class.as_user(post.user) do
      create_list(:reply, 6, post: post, user: post.user)
    end

    Audited.audit_class.as_user(post.user) do
      replies[1].touch # rubocop:disable Rails/SkipsModelValidations
      replies[3].update!(character: create(:character, user: post.user))
      replies[2].update!(content: 'new content')
      1.upto(5) { |i| replies[4].update!(content: 'message' + i.to_s) }
    end
    Audited.audit_class.as_user(create(:mod_user)) do
      replies[5].update!(content: 'new content')
    end

    counts = replies.map(&:id).zip([1, 1, 2, 2, 6, 2]).to_h
    counts[:post] = 1

    get :show, params: { id: post.id }
    expect(assigns(:audits)).to eq(counts)
    Reply.auditing_enabled = false
    Post.auditing_enabled = false
  end

  context "with render_views" do
    let!(:post) { create(:post, with_icon: true, with_character: true) }
    let!(:reply) { create(:reply, post: post, with_icon: true, with_character: true) }

    render_views

    it "renders HAML with additional attributes" do
      calias = create(:alias, character: reply.character)
      reply.update!(character_alias: calias)

      get :show, params: { id: post.id }

      expect(response.status).to eq(200)
      expect(response.body).to include(post.subject)
      expect(response.body).to include('header-right')
    end

    it "renders HAML for logged in user" do
      character = create(:character)
      login_as(character.user)
      get :show, params: { id: post.id }
      expect(response.status).to eq(200)
      expect(response.body).to include('Join Thread')
    end

    it "flat view renders HAML properly" do
      get :show, params: { id: post.id, view: 'flat' }
      expect(response.status).to eq(200)
      expect(response.body).to include(post.subject)
      expect(response.body).not_to include('header-right')
    end

    it "displays quick switch properly" do
      login_as(reply.user)
      get :show, params: { id: post.id }
      expect(response.status).to eq(200)
    end
  end

  context "RSS feed" do
    render_views

    let!(:post) { create(:post, subject: 'a feed thread', description: 'a thread description') }
    let!(:reply) { create(:reply, post: post, content: 'a reply body') }

    it "renders a well-formed RSS feed without requiring login" do
      get :show, params: { id: post.id, format: :rss }
      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('application/rss+xml')

      doc = Nokogiri::XML(response.body) { |config| config.strict }
      expect(doc.errors).to be_empty
      expect(doc.at_xpath('/rss/channel/title').text).to eq('a feed thread')
      items = doc.xpath('/rss/channel/item')
      expect(items.size).to eq(2) # the reply and the opening post
      expect(response.body).to include('a reply body')
    end

    it "requires permission" do
      post.update!(privacy: :private)
      get :show, params: { id: post.id, format: :rss }
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "shows the newest items first and includes the opening post last" do
      get :show, params: { id: post.id, format: :rss }
      items = assigns(:feed_items)
      expect(items.first).to eq(reply)
      expect(items.last).to eq(post)
    end

    it "limits the number of items and drops the opening post when full" do
      create_list(:reply, WritableController::RSS_ITEM_LIMIT + 2, post: post)
      get :show, params: { id: post.id, format: :rss }
      items = assigns(:feed_items)
      expect(items.size).to eq(WritableController::RSS_ITEM_LIMIT)
      expect(items).not_to include(post)
    end

    it "advertises the feed for autodiscovery on the HTML thread page" do
      get :show, params: { id: post.id }
      expect(response.body).to include('application/rss+xml')
      expect(response.body).to include(post_url(post, format: :rss))
    end

    it "includes the subscriber's token in the feed URL when logged in" do
      viewer = create(:user)
      login_as(viewer)
      get :show, params: { id: post.id }
      expect(response.body).to include("rss_token=#{viewer.rss_token}")
    end

    context "token authentication" do
      let(:reader) { create(:user) }
      let!(:hidden_post) { create(:post, privacy: :registered, subject: 'members only thread') }

      it "lets a logged-out reader use a valid rss_token to read a non-public thread" do
        get :show, params: { id: hidden_post.id, format: :rss, rss_token: reader.rss_token }
        expect(response).to have_http_status(200)
        expect(response.body).to include('members only thread')
      end

      it "denies a non-public thread when no token is given" do
        get :show, params: { id: hidden_post.id, format: :rss }
        expect(response).to redirect_to(continuities_url)
        expect(flash[:error]).to eq("You do not have permission to view this post.")
      end

      it "denies an invalid rss_token" do
        get :show, params: { id: hidden_post.id, format: :rss, rss_token: 'not-a-real-token' }
        expect(response).to redirect_to(continuities_url)
      end

      it "ignores the token for a suspended user" do
        reader.update!(role_id: Permissible::SUSPENDED)
        get :show, params: { id: hidden_post.id, format: :rss, rss_token: reader.rss_token }
        expect(response).to redirect_to(continuities_url)
      end

      it "does not grant HTML access via rss_token" do
        private_post = create(:post, privacy: :private)
        get :show, params: { id: private_post.id, rss_token: reader.rss_token }
        expect(response).to redirect_to(continuities_url)
        expect(flash[:error]).to eq("You do not have permission to view this post.")
      end
    end
  end

  context "with at_id" do
    let(:post) { create(:post) }
    let(:second_last_reply) { post.replies.ordered.last(2).first }

    before(:each) do
      create_list(:reply, 5, post: post)
    end

    it "shows error if reply not found" do
      get :show, params: { id: post.id, at_id: -1 }
      expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
      expect(assigns(:replies).count).to eq(5)
    end

    context "unread" do
      it "shows error if not logged in" do
        get :show, params: { id: post.id, at_id: 'unread' }
        expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
        expect(assigns(:replies).count).to eq(5)
      end

      it "shows error if no unread" do
        post.mark_read(user)
        login_as(user)
        get :show, params: { id: post.id, at_id: 'unread' }
        expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
        expect(assigns(:replies).count).to eq(5)
      end

      it "works" do
        post.mark_read(user, at_time: post.replies.ordered[2].created_at)
        expect(post.first_unread_for(user)).to eq(second_last_reply)
        login_as(user)
        get :show, params: { id: post.id, at_id: 'unread', per_page: 1 }
        expect(assigns(:replies)).to eq([second_last_reply])
        expect(assigns(:unread)).to eq(second_last_reply)
        expect(assigns(:paginate_params)['at_id']).to eq(second_last_reply.id)
      end
    end

    it "shows error when reply is wrong post" do
      get :show, params: { id: post.id, at_id: create(:reply).id }
      expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
      expect(assigns(:replies).count).to eq(5)
    end

    context "with specified reply" do
      let(:last_reply) { post.replies.ordered.last }

      it "works" do
        get :show, params: { id: post.id, at_id: last_reply.id }
        expect(assigns(:replies)).to eq([last_reply])
        expect(assigns(:replies).current_page.to_i).to eq(1)
        expect(assigns(:replies).per_page).to eq(25)
      end

      it "works with page settings" do
        get :show, params: { id: post.id, at_id: second_last_reply.id, per_page: 1 }
        expect(assigns(:replies)).to eq([second_last_reply])
        expect(assigns(:replies).current_page.to_i).to eq(1)
        expect(assigns(:replies).per_page).to eq(1)
      end

      it "prioritizes incompatible page settings" do
        get :show, params: { id: post.id, at_id: second_last_reply.id, per_page: 1, page: 2 }
        expect(assigns(:replies)).to eq([last_reply])
        expect(assigns(:replies).current_page.to_i).to eq(2)
        expect(assigns(:replies).per_page).to eq(1)
      end
    end
  end

  context "page=unread" do
    let(:time) { 5.minutes.ago }
    let!(:reply) { Timecop.freeze(time) { create(:reply, post: post, user: post.user) } }

    before(:each) do
      login_as(user)
      Timecop.freeze(time + 1.second) { create(:reply, post: post, user: post.user) }
      Timecop.freeze(time + 2.seconds) { create(:reply, post: post, user: post.user) }
    end

    it "goes to the end if you're up to date" do
      post.mark_read(user)
      get :show, params: { id: post.id, page: 'unread', per_page: 1 }
      expect(assigns(:page)).to eq(3)
    end

    it "goes to beginning if you've never read it" do
      get :show, params: { id: post.id, page: 'unread' }
      expect(assigns(:page)).to eq(1)
    end

    it "goes to post page if you're behind" do
      post.mark_read(user, at_time: reply.created_at)
      get :show, params: { id: post.id, page: 'unread', per_page: 1 }
      expect(assigns(:page)).to eq(2)
    end
  end

  context "with author" do
    let(:post) { create(:post, user: user, authors_locked: true, with_icon: true, with_character: true) }

    before(:each) { login_as(user) }

    it "works" do
      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
    end

    it "sets reply variable using build_new_reply_for" do
      # mock Post.find_by_id so we can mock post.build_new_reply_for
      allow(Post).to receive(:find_by).and_call_original
      allow(Post).to receive(:find_by).with({ id: post.id.to_s }).and_return(post)

      allow(post).to receive(:build_new_reply_for).and_call_original
      expect(post).to receive(:build_new_reply_for).with(user, an_instance_of(ActionController::Parameters).and(be_empty))
      expect(controller).to receive(:setup_layout_gon).and_call_original

      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:reply)).not_to be_nil
      expect(assigns(:javascripts)).to include('posts/show', 'posts/editor')
    end
  end

  context "with non-author who can write" do
    let(:post) { create(:post, authors_locked: false, with_icon: true, with_character: true) }

    before(:each) { login_as(user) }

    it "works" do
      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
    end

    it "sets reply variable using build_new_reply_for" do
      # mock Post.find_by_id so we can mock post.build_new_reply_for
      allow(Post).to receive(:find_by).and_call_original
      allow(Post).to receive(:find_by).with({ id: post.id.to_s }).and_return(post)

      allow(post).to receive(:build_new_reply_for).and_call_original
      expect(post).to receive(:build_new_reply_for).with(user, an_instance_of(ActionController::Parameters).and(be_empty)).and_call_original

      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:reply)).not_to be_nil
    end
  end

  context "with user who cannot write" do
    it "works and does not call build_new_reply_for" do
      post = create(:post, authors_locked: true)

      # mock Post.find_by_id so we can mock post.build_new_reply_for
      allow(Post).to receive(:find_by).and_call_original
      allow(Post).to receive(:find_by).with({ id: post.id.to_s }).and_return(post)

      login_as(user)
      expect(post).not_to receive(:build_new_reply_for)

      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:reply)).to be_nil
    end
  end
  # TODO WAY more tests
end
