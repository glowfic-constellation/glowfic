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

  it "marks read multiple times" do
    login_as(user)
    expect(post.last_read(user)).to be_nil
    get :show, params: { id: post.id }
    last_read = post.reload.last_read(user)
    expect(last_read).not_to be_nil

    Timecop.freeze(last_read + 1.second) do
      reply = create(:reply, post: post, user: post.user)
      expect(reply.created_at).not_to be_the_same_time_as(last_read)
      get :show, params: { id: post.id }
      cur_read = post.reload.last_read(user)
      expect(last_read).not_to be_the_same_time_as(cur_read)
      expect(last_read.to_i).to be < cur_read.to_i
    end
  end

  it "marks read even if post is ignored" do
    login_as(user)
    post.ignore(user)
    expect(post.reload.first_unread_for(user)).to eq(post)

    get :show, params: { id: post.id }
    expect(post.reload.first_unread_for(user)).to be_nil
    last_read = post.last_read(user)

    Timecop.freeze(last_read + 1.second) do
      reply = create(:reply, post: post, user: post.user)
      expect(reply.created_at).not_to be_the_same_time_as(last_read)
      expect(post.reload.first_unread_for(user)).to eq(reply)
      get :show, params: { id: post.id }
      expect(post.reload.first_unread_for(user)).to be_nil
    end
  end

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
    create_list(:reply, 5, post: post, user: post.user)
    get :show, params: { id: post.id, per_page: 1, page: 10 }
    expect(response).to redirect_to(post_url(post, page: 5, per_page: 1))
  end

  it "handles page=last with replies" do
    create_list(:reply, 5, post: post, user: post.user)
    get :show, params: { id: post.id, per_page: 1, page: 'last' }
    expect(assigns(:page)).to eq(5)
    expect(response).to have_http_status(200)
    expect(response).to render_template(:show)
  end

  it "handles page=last with no replies" do
    get :show, params: { id: post.id, page: 'last' }
    expect(assigns(:page)).to eq(1)
    expect(response).to have_http_status(200)
    expect(response).to render_template(:show)
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
    render_views

    it "renders HAML with additional attributes" do
      coauthor = create(:user)
      post = create(:post, with_icon: true, with_character: true, unjoined_authors: [coauthor])
      reply = create(:reply, user: coauthor, post: post, with_icon: true, with_character: true)
      calias = create(:alias, character: reply.character)
      reply.update!(character_alias: calias)
      get :show, params: { id: post.id }
      expect(response.status).to eq(200)
      expect(response.body).to include(post.subject)
      expect(response.body).to include('header-right')
    end

    it "renders HAML for logged in user" do
      post.update!(authors_locked: false)
      create(:reply, post: post)
      character = create(:character)
      login_as(character.user)
      get :show, params: { id: post.id }
      expect(response.status).to eq(200)
      expect(response.body).to include('Join Thread')
    end

    it "flat view renders HAML properly" do
      post = create(:post, with_icon: true, with_character: true)
      create(:reply, post: post, user: post.user, with_icon: true, with_character: true)
      get :show, params: { id: post.id, view: 'flat' }
      expect(response.status).to eq(200)
      expect(response.body).to include(post.subject)
      expect(response.body).not_to include('header-right')
    end

    it "displays quick switch properly" do
      reply = create(:reply, user: post.user, post: post, with_icon: true, with_character: true)
      login_as(reply.user)
      get :show, params: { id: post.id }
      expect(response.status).to eq(200)
    end
  end

  context "with at_id" do
    let(:post) { create(:post) }

    before(:each) do
      create_list(:reply, 5, post: post, user: post.user)
    end

    it "shows error if reply not found" do
      get :show, params: { id: post.id, at_id: -1 }
      expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
      expect(assigns(:replies).count).to eq(5)
    end

    it "shows error if unread not logged in" do
      get :show, params: { id: post.id, at_id: 'unread' }
      expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
      expect(assigns(:replies).count).to eq(5)
    end

    it "shows error if no unread" do
      user = create(:user)
      post.mark_read(user)
      login_as(user)
      get :show, params: { id: post.id, at_id: 'unread' }
      expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
      expect(assigns(:replies).count).to eq(5)
    end

    it "shows error when reply is wrong post" do
      get :show, params: { id: post.id, at_id: create(:reply).id }
      expect(flash[:error]).to eq("Could not locate specified reply, defaulting to first page.")
      expect(assigns(:replies).count).to eq(5)
    end

    it "works for specified reply" do
      last_reply = post.replies.ordered.last
      get :show, params: { id: post.id, at_id: last_reply.id }
      expect(assigns(:replies)).to eq([last_reply])
      expect(assigns(:replies).current_page.to_i).to eq(1)
      expect(assigns(:replies).per_page).to eq(25)
    end

    it "works for specified reply with page settings" do
      second_last_reply = post.replies.ordered.last(2).first
      get :show, params: { id: post.id, at_id: second_last_reply.id, per_page: 1 }
      expect(assigns(:replies)).to eq([second_last_reply])
      expect(assigns(:replies).current_page.to_i).to eq(1)
      expect(assigns(:replies).per_page).to eq(1)
    end

    it "works for page settings incompatible with specified reply" do
      last_reply = post.replies.ordered.last
      second_last_reply = post.replies.ordered.last(2).first
      get :show, params: { id: post.id, at_id: second_last_reply.id, per_page: 1, page: 2 }
      expect(assigns(:replies)).to eq([last_reply])
      expect(assigns(:replies).current_page.to_i).to eq(2)
      expect(assigns(:replies).per_page).to eq(1)
    end

    it "works for unread" do
      third_reply = post.replies.ordered[2]
      second_last_reply = post.replies.ordered[-2]
      user = create(:user)
      post.mark_read(user, at_time: third_reply.created_at)
      expect(post.first_unread_for(user)).to eq(second_last_reply)
      login_as(user)
      get :show, params: { id: post.id, at_id: 'unread', per_page: 1 }
      expect(assigns(:replies)).to eq([second_last_reply])
      expect(assigns(:unread)).to eq(second_last_reply)
      expect(assigns(:paginate_params)['at_id']).to eq(second_last_reply.id)
    end
  end

  context "page=unread" do
    it "goes to the end if you're up to date" do
      post = create(:post)
      create_list(:reply, 3, post: post, user: post.user)
      user = create(:user)
      post.mark_read(user)
      login_as(user)
      get :show, params: { id: post.id, page: 'unread', per_page: 1 }
      expect(assigns(:page)).to eq(3)
    end

    it "goes to beginning if you've never read it" do
      post = create(:post)
      user = create(:user)
      login_as(user)
      get :show, params: { id: post.id, page: 'unread' }
      expect(assigns(:page)).to eq(1)
    end

    it "goes to post page if you're behind" do
      post = create(:post)
      reply1 = create(:reply, post: post, user: post.user)
      Timecop.freeze(reply1.created_at + 1.second) { create(:reply, post: post, user: post.user) } # second reply
      Timecop.freeze(reply1.created_at + 2.seconds) { create(:reply, post: post, user: post.user) } # third reply
      user = create(:user)
      post.mark_read(user, at_time: reply1.created_at)
      login_as(user)
      get :show, params: { id: post.id, page: 'unread', per_page: 1 }
      expect(assigns(:page)).to eq(2)
    end
  end

  context "with author" do
    it "works" do
      post = create(:post)
      login_as(post.user)
      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
    end

    it "sets reply variable using build_new_reply_for" do
      post = create(:post, authors_locked: false, with_icon: true, with_character: true)
      user = post.user
      post.reload

      # mock Post.find_by_id so we can mock post.build_new_reply_for
      allow(Post).to receive(:find_by_id).with(post.id.to_s).and_return(post)

      login_as(user)
      expect(post).to be_taggable_by(user)
      expect(post).to receive(:build_new_reply_for).with(user, {}).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:reply)).not_to be_nil
      expect(assigns(:javascripts)).to include('posts/show', 'posts/editor')
    end
  end

  context "with non-author who can write" do
    it "works" do
      post = create(:post, authors_locked: false)
      user = create(:user)
      login_as(user)
      expect(post).to be_taggable_by(user)
      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
    end

    it "sets reply variable using build_new_reply_for" do
      post = create(:post, authors_locked: false, with_icon: true, with_character: true)
      user = create(:user)
      post.reload

      # mock Post.find_by_id so we can mock post.build_new_reply_for
      allow(Post).to receive(:find_by_id).with(post.id.to_s).and_return(post)

      login_as(user)
      expect(post).to be_taggable_by(user)
      expect(post).to receive(:build_new_reply_for).with(user, {}).and_call_original

      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:reply)).not_to be_nil
    end
  end

  context "with user who cannot write" do
    it "works and does not call build_new_reply_for" do
      post = create(:post, authors_locked: true)
      user = create(:user)
      post.reload

      # mock Post.find_by_id so we can mock post.build_new_reply_for
      allow(Post).to receive(:find_by_id).with(post.id.to_s).and_return(post)

      login_as(user)
      expect(post).not_to be_taggable_by(user)
      expect(post).not_to receive(:build_new_reply_for)

      get :show, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:reply)).to be_nil
    end
  end
  # TODO WAY more tests
end
