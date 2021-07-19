RSpec.describe PostsController, 'GET unread' do
  let(:controller_action) { "unread" }
  let(:params) { {} }
  let(:assign_variable) { :posts }

  it "requires login" do
    get :unread
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "succeeds" do
    login
    get :unread
    expect(response).to have_http_status(200)
    expect(assigns(:started)).not_to eq(true)
    expect(assigns(:page_title)).to eq('Unread Threads')
    expect(assigns(:posts)).to be_empty
    expect(assigns(:hide_quicklinks)).to eq(true)
  end

  it "succeeds for reader accounts" do
    login_as(create(:reader_user))
    get :unread
    expect(response).to have_http_status(200)
    expect(assigns(:started)).not_to eq(true)
    expect(assigns(:page_title)).to eq('Unread Threads')
    expect(assigns(:posts)).to be_empty
    expect(assigns(:hide_quicklinks)).to eq(true)
  end

  it "shows appropriate posts" do
    user = create(:user)
    time = 10.minutes.ago

    unread_post = create(:post) # post
    opened_post1, opened_post2, read_post1, read_post2, hidden_post = Timecop.freeze(time) do
      opened_post1 = create(:post, authors_locked: false) # post & reply, read post
      opened_post2 = create(:post, authors_locked: false) # post & 2 replies, read post & reply
      create(:reply, post: opened_post2) # reply1
      read_post1 = create(:post, authors_locked: false) # post
      read_post2 = create(:post, authors_locked: false) # post & reply
      hidden_post = create(:post, authors_locked: false) # post
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

    login_as(user)
    get :unread
    expect(response).to have_http_status(200)
    expect(assigns(:started)).not_to eq(true)
    expect(assigns(:page_title)).to eq('Unread Threads')
    expect(assigns(:posts)).to match_array([unread_post, opened_post1, opened_post2])
    expect(assigns(:hide_quicklinks)).to eq(true)
  end

  it "orders posts by tagged_at" do
    login
    post2 = create(:post)
    post3 = create(:post)
    post1 = create(:post)
    create(:reply, post: post2, user: post2.user)
    create(:reply, post: post1, user: post1.user)

    get :unread
    expect(assigns(:posts)).to eq([post1, post2, post3])
  end

  it "manages board/post read time mismatches" do
    user = create(:user)

    # no views exist
    unread_post = create(:post)

    # only post view exists
    post_unread_post = create(:post)
    post_unread_post.mark_read(user, at_time: post_unread_post.created_at - 1.second, force: true)
    post_read_post = create(:post)
    post_read_post.mark_read(user)

    # only board view exists
    board_unread_post = create(:post)
    board_unread_post.board.mark_read(user, at_time: board_unread_post.created_at - 1.second, force: true)
    board_read_post = create(:post)
    board_read_post.board.mark_read(user)

    # both exist
    both_unread_post = create(:post)
    both_unread_post.mark_read(user, at_time: both_unread_post.created_at - 1.second, force: true)
    both_unread_post.board.mark_read(user, at_time: both_unread_post.created_at - 1.second, force: true)
    both_board_read_post = create(:post)
    both_board_read_post.mark_read(user, at_time: both_unread_post.created_at - 1.second, force: true)
    both_board_read_post.board.mark_read(user)
    both_post_read_post = create(:post)
    both_post_read_post.board.mark_read(user, at_time: both_unread_post.created_at - 1.second, force: true)
    both_post_read_post.mark_read(user)
    both_read_post = create(:post)
    both_read_post.mark_read(user)
    both_read_post.board.mark_read(user)

    # board ignored
    board_ignored = create(:post)
    board_ignored.mark_read(user, at_time: both_unread_post.created_at - 1.second, force: true)
    board_ignored.board.ignore(user)

    login_as(user)
    get :unread
    expect(assigns(:posts)).to match_array([unread_post, post_unread_post, board_unread_post, both_unread_post, both_board_read_post])
  end

  context "opened" do
    it "accepts parameter to force opened mode" do
      user = create(:user)
      expect(user.unread_opened).not_to eq(true)
      login_as(user)
      get :unread, params: { started: 'true' }
      expect(response).to have_http_status(200)
      expect(assigns(:started)).to eq(true)
      expect(assigns(:page_title)).to eq('Opened Threads')
    end

    it "shows appropriate posts" do
      user = create(:user, unread_opened: true)
      time = 10.minutes.ago

      unread_post = create(:post) # post
      opened_post1, opened_post2, read_post1, read_post2, hidden_post = Timecop.freeze(time) do
        opened_post1 = create(:post, authors_locked: false) # post & reply, read post
        opened_post2 = create(:post, authors_locked: false) # post & 2 replies, read post & reply
        create(:reply, post: opened_post2) # reply1
        read_post1 = create(:post, authors_locked: false) # post
        read_post2 = create(:post, authors_locked: false) # post & reply
        hidden_post = create(:post, authors_locked: false) # post & reply
        [opened_post1, opened_post2, read_post1, read_post2, hidden_post]
      end
      reply2, reply3 = Timecop.freeze(time + 5.minutes) do
        reply2 = create(:reply, post: opened_post1)
        reply3 = create(:reply, post: opened_post2)
        create(:reply, post: read_post2) # reply4
        create(:reply, post: hidden_post) # reply5
        [reply2, reply3]
      end

      opened_post1.mark_read(user, at_time: time)
      opened_post2.mark_read(user, at_time: time)
      read_post1.mark_read(user)
      read_post2.mark_read(user)
      hidden_post.mark_read(user, at_time: time)
      hidden_post.ignore(user)

      expect(unread_post.reload.first_unread_for(user)).to eq(unread_post)
      expect(opened_post1.reload.first_unread_for(user)).to eq(reply2)
      expect(opened_post2.reload.first_unread_for(user)).to eq(reply3)
      expect(read_post1.reload.first_unread_for(user)).to be_nil
      expect(read_post2.reload.first_unread_for(user)).to be_nil
      expect(hidden_post.reload).to be_ignored_by(user)

      login_as(user)
      get :unread
      expect(response).to have_http_status(200)
      expect(assigns(:started)).to eq(true)
      expect(assigns(:page_title)).to eq('Opened Threads')
      expect(assigns(:posts)).to match_array([opened_post1, opened_post2])
      expect(assigns(:hide_quicklinks)).to eq(true)
    end
  end

  context "when logged in" do
    include_examples "logged in post list"
  end
end
