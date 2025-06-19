RSpec.describe PostsController, 'GET unread' do
  let(:controller_action) { "unread" }
  let(:params) { {} }
  let(:assign_variable) { :posts }
  let(:user) { create(:user) }

  def setup_posts
    time = 10.minutes.ago

    unread_post = create(:post) # post
    opened_post1, opened_post2, read_post1, read_post2, hidden_post = Timecop.freeze(time) do
      opened_post1 = create(:post) # post & reply, read post
      opened_post2 = create(:post) # post & 2 replies, read post & reply
      create(:reply, post: opened_post2) # reply1
      read_post1 = create(:post) # post
      read_post2 = create(:post) # post & reply
      hidden_post = create(:post) # post
      [opened_post1, opened_post2, read_post1, read_post2, hidden_post]
    end
    reply2, reply3 = Timecop.freeze(time + 5.minutes) do
      reply2 = create(:reply, post: opened_post1)
      reply3 = create(:reply, post: opened_post2)
      create(:reply, post: read_post2) # reply 4
      [reply2, reply3]
    end

    opened_post1.mark_read(user, at_time: time)
    opened_post2.mark_read(user, at_time: time)
    read_post1.mark_read(user)
    read_post2.mark_read(user)
    hidden_post.ignore(user)

    expect(unread_post.reload.first_unread_for(user)).to eq(unread_post)
    expect(opened_post1.reload.first_unread_for(user)).to eq(reply2)
    expect(opened_post2.reload.first_unread_for(user)).to eq(reply3)
    expect(read_post1.reload.first_unread_for(user)).to be_nil
    expect(read_post2.reload.first_unread_for(user)).to be_nil
    expect(hidden_post.reload).to be_ignored_by(user)

    [unread_post, opened_post1, opened_post2]
  end

  it "requires login" do
    get :unread
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  context "loading posts" do
    before(:each) { login_as(user) }

    it "succeeds" do
      get :unread
      expect(response).to have_http_status(200)
      expect(assigns(:started)).not_to eq(true)
      expect(assigns(:page_title)).to eq('Unread Threads')
      expect(assigns(:posts)).to be_empty
      expect(assigns(:hide_quicklinks)).to eq(true)
    end

    it "succeeds for reader accounts" do
      user.update!(role_id: Permissible::READONLY)
      get :unread
      expect(response).to have_http_status(200)
      expect(assigns(:started)).not_to eq(true)
      expect(assigns(:page_title)).to eq('Unread Threads')
      expect(assigns(:posts)).to be_empty
      expect(assigns(:hide_quicklinks)).to eq(true)
    end

    it "shows appropriate posts" do
      posts = setup_posts
      login_as(user)
      get :unread
      expect(response).to have_http_status(200)
      expect(assigns(:started)).not_to eq(true)
      expect(assigns(:page_title)).to eq('Unread Threads')
      expect(assigns(:posts)).to match_array(posts)
      expect(assigns(:hide_quicklinks)).to eq(true)
    end

    it "orders posts by tagged_at" do
      post2 = create(:post)
      post3 = create(:post)
      post1 = create(:post)
      create(:reply, post: post2)
      create(:reply, post: post1)

      get :unread
      expect(assigns(:posts)).to eq([post1, post2, post3])
    end

    it "manages board/post read time mismatches" do
      now = Time.zone.now
      # no views exist
      unread_post = create(:post)

      # only post view exists
      post_unread_post, post_read_post = Timecop.freeze(now) { create_list(:post, 2) }

      Timecop.freeze(now + 1.second) do
        post_unread_post.mark_read(user)
        post_read_post.mark_read(user)
      end

      Timecop.freeze(now + 3.seconds) { create(:reply, post: post_unread_post) }

      # only board view exists
      board_unread_post, board_read_post = Timecop.freeze(now) { create_list(:post, 2) }

      Timecop.freeze(now + 1.second) do
        board_unread_post.mark_read(user)
        board_read_post.mark_read(user)
      end

      Timecop.freeze(now + 3.seconds) { create(:reply, post: board_unread_post) }

      # both exist
      both_unread_post, both_board_read_post, both_post_read_post, both_read_post = Timecop.freeze(now) { create_list(:post, 4) }

      Timecop.freeze(now + 1.second) do
        both_unread_post.mark_read(user)
        both_unread_post.board.mark_read(user)
        both_board_read_post.mark_read(user)
        both_post_read_post.board.mark_read(user)
      end

      Timecop.freeze(now + 3.seconds) do
        create(:reply, post: both_unread_post)
        create(:reply, post: both_board_read_post)
        create(:reply, post: both_post_read_post)
      end

      Timecop.freeze(now + 5.seconds) do
        both_board_read_post.board.mark_read(user)
        both_post_read_post.mark_read(user)
        both_read_post.mark_read(user)
        both_read_post.board.mark_read(user)
      end

      # board ignored
      board_ignored = Timecop.freeze(now) { create(:post) }
      board_ignored.mark_read(user, at_time: now)
      board_ignored.board.ignore(user)

      get :unread
      expect(assigns(:posts)).to match_array([unread_post, post_unread_post, board_unread_post, both_unread_post, both_board_read_post])
    end
  end

  context "opened" do
    before(:each) { login_as(user) }

    it "accepts parameter to force opened mode" do
      get :unread, params: { started: 'true' }
      expect(response).to have_http_status(200)
      expect(assigns(:started)).to eq(true)
      expect(assigns(:page_title)).to eq('Opened Threads')
    end

    it "shows appropriate posts" do
      user.update!(unread_opened: true)
      posts = setup_posts

      get :unread
      expect(response).to have_http_status(200)
      expect(assigns(:started)).to eq(true)
      expect(assigns(:page_title)).to eq('Opened Threads')
      expect(assigns(:posts)).to match_array(posts[1..])
      expect(assigns(:hide_quicklinks)).to eq(true)
    end
  end

  context "when logged in" do
    it_behaves_like "logged in post list"
  end
end
