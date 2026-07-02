RSpec.describe RepliesController, 'GET show' do
  let(:reply) { create(:reply) }

  it "requires valid reply" do
    get :show, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post access" do
    expect(reply.user_id).not_to eq(reply.post.user_id)
    expect(reply.post.visible_to?(reply.user)).to eq(true)

    reply.post.update!(privacy: :private)
    reply.post.save!
    reply.reload
    expect(reply.post.visible_to?(reply.user)).to eq(false)

    login_as(reply.user)
    get :show, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "succeeds when logged out" do
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')
  end

  it "works for reader accounts" do
    login_as(create(:reader_user))
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
  end

  it "calculates OpenGraph meta" do
    user = create(:user, username: 'user1')
    user2 = create(:user, username: 'user2')
    board = create(:board, name: 'example board')
    section = create(:board_section, board: board, name: 'example section')
    post = create(:post, board: board, section: section, user: user, subject: 'a post', description: 'Test.')
    create_list(:reply, 25, post: post, user: user)
    reply = create(:reply, post: post, user: user2)
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')

    meta_og = assigns(:meta_og)
    expect(meta_og[:url]).to eq(post_url(post, page: 2))
    expect(meta_og[:title]).to eq('a post · example board » example section')
    expect(meta_og[:description]).to eq('Test. (user1, user2 – page 2 of 2)')
  end

  it "succeeds when logged in" do
    login
    get :show, params: { id: reply.id }
    expect(response).to have_http_status(200)
    expect(assigns(:javascripts)).to include('posts/show')
  end

  it "has more tests" do
    skip
  end

  context "permalink read position" do
    let(:user) { create(:user) }
    let(:post) { create(:post) }
    let!(:replies) do
      (1..12).map { |i| Timecop.freeze(post.created_at + i.minutes) { create(:reply, post: post) } }
    end

    before(:each) { login_as(user) }

    it "leaves read position untouched and flags 'earlier' when the thread has never been read" do
      target = replies[10] # page 3 of 3 with per_page: 5

      get :show, params: { id: target.id, per_page: 5 }

      expect(response).to have_http_status(200)
      expect(assigns(:permalink_reply)).to eq(target)
      expect(assigns(:permalink_read_direction)).to eq(:earlier)
      expect(Post::View.where(post: post, user: user)).not_to exist
    end

    it "leaves read position untouched and flags 'earlier' when partially read" do
      Timecop.freeze(replies[2].created_at + 30.seconds) { post.mark_read(user) }
      target = replies[10] # page 3, ahead of the unread boundary on page 1

      get :show, params: { id: target.id, per_page: 5 }

      expect(assigns(:permalink_read_direction)).to eq(:earlier)
      expect(post.reload.last_read(user)).to be_the_same_time_as(replies[2].created_at + 30.seconds)
    end

    it "leaves read position untouched and flags 'later' when fully read" do
      Timecop.freeze(replies.last.created_at + 30.seconds) { post.mark_read(user) }
      target = replies[1] # page 1, behind the fully-read boundary on page 3

      get :show, params: { id: target.id, per_page: 5 }

      expect(assigns(:permalink_read_direction)).to eq(:later)
      expect(post.reload.last_read(user)).to be_the_same_time_as(replies.last.created_at + 30.seconds)
    end

    it "updates read position normally when the permalink matches the unread position" do
      target = replies[0] # page 1, matching the never-read boundary

      get :show, params: { id: target.id, per_page: 5 }

      expect(assigns(:permalink_read_direction)).to be_nil
      expect(post.reload.last_read(user)).not_to be_nil
    end
  end
end
