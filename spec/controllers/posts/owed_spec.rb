RSpec.describe PostsController, 'GET owed' do
  it "requires login" do
    get :owed
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    login_as(create(:reader_user))
    get :owed
    expect(response).to redirect_to(continuities_path)
    expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
  end

  it "succeeds" do
    login
    get :owed
    expect(response.status).to eq(200)
    expect(assigns(:page_title)).to eq('Replies Owed')
  end

  it "lists number of posts in the title if present" do
    user = create(:user)
    login_as(user)
    post = create(:post, user: user)
    create(:reply, post: post)
    get :owed
    expect(response.status).to eq(200)
    expect(assigns(:page_title)).to eq('[1] Replies Owed')
  end

  context "with views" do
    render_views

    def create_owed(user)
      post = create(:post, user: user)
      create(:reply, post: post)
      post.mark_read(user)
    end

    it "succeeds" do
      user = create(:user)
      login_as(user)
      create_owed(user)
      get :owed
      expect(response.status).to eq(200)
      expect(response.body).to include('note_go_strong')
    end

    it "succeeds with dark" do
      user = create(:user, layout: 'starrydark')
      login_as(user)
      create_owed(user)
      get :owed
      expect(response.status).to eq(200)
      expect(response.body).to include('bullet_go_strong')
    end
  end

  context "with hidden" do
    let(:user) { create(:user) }
    let(:unhidden_post) { create(:post, user: user) }
    let(:hidden_post) { create(:post, user: user) }

    before(:each) do
      login_as(user)
      create(:reply, post: unhidden_post)
      create(:reply, post: hidden_post)
      author = hidden_post.post_authors.where(user_id: user.id).first
      author.update!(can_owe: false)
    end

    it "does not show hidden without arg" do
      get :owed
      expect(assigns(:posts)).to eq([unhidden_post])
    end

    it "shows only hidden with arg" do
      get :owed, params: { view: 'hidden' }
      expect(assigns(:posts)).to eq([hidden_post])
    end
  end

  context "with hiatused" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    before(:each) do
      login_as(user)
      create(:post)
    end

    it "shows hiatused posts" do
      post = create(:post, user: user)
      create(:reply, post: post, user: other_user)
      post.update!(status: :hiatus)

      get :owed, params: { view: 'hiatused' }
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to eq([post])
    end

    it "shows auto-hiatused posts" do
      post = nil
      Timecop.freeze(1.month.ago) do
        post = create(:post, user: user)
        create(:reply, post: post, user: other_user)
      end
      get :owed, params: { view: 'hiatused' }
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to eq([post])
    end
  end

  context "with posts" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:post) { create(:post, user: user) }

    before(:each) do
      other_user
      login_as(user)
    end

    it "shows a post if replied to by someone else" do
      create(:reply, post_id: post.id, user_id: other_user.id)

      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to match_array([post])
    end

    it "hides a post if you reply to it" do
      create(:reply, post_id: post.id, user_id: other_user.id)
      create(:reply, post_id: post.id, user_id: user.id)

      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to be_empty
    end

    it "does not show posts from site_testing" do
      site_test = create(:board, id: Continuity::ID_SITETESTING)

      post.board = site_test
      post.save!
      create(:reply, post_id: post.id, user_id: other_user.id)

      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to be_empty
    end

    it "hides completed threads" do
      create(:reply, post: post, user: other_user)
      post.update!(status: :complete)
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to be_empty
    end

    it "hides abandoned threads" do
      create(:reply, post: post, user: other_user)
      post.update!(status: :abandoned)
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to be_empty
    end

    it "show hiatused threads by default" do
      create(:reply, post_id: post.id, user_id: other_user.id)
      post.update!(status: :hiatus)

      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to match_array([post])
    end

    it "optionally hides hiatused threads" do
      create(:reply, post_id: post.id, user_id: other_user.id)
      post.update!(status: :hiatus)

      user.hide_hiatused_tags_owed = true
      user.save!
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to be_empty
    end

    it "shows threads the user has been invited to" do
      post = create(:post, user: other_user, unjoined_authors: [user])
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to match_array([post])
    end

    it "hides threads the user has manually removed themselves from" do
      post = create(:post, user: other_user, tagging_authors: [other_user])
      create(:reply, post: post, user: user)
      create(:reply, post: post, user: other_user)
      post.opt_out_of_owed(user)
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to match_array([])
    end

    it "orders posts by tagged_at" do
      post2 = create(:post, user_id: user.id)
      post3 = create(:post, user_id: user.id)
      post1 = create(:post, user_id: user.id)
      create(:reply, post_id: post3.id, user_id: other_user.id)
      create(:reply, post_id: post2.id, user_id: other_user.id)
      create(:reply, post_id: post1.id, user_id: other_user.id)
      get :owed
      expect(assigns(:posts)).to eq([post1, post2, post3])
    end

    it "shows threads with existing drafts" do
      create(:reply, post: post, user: other_user)
      create(:reply, post: post, user: user)
      create(:reply_draft, post: post, user: user)
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to match_array([post])
    end

    it "does not show threads with drafts by coauthors" do
      create(:reply, post: post, user: other_user)
      create(:reply, post: post, user: user)
      create(:reply_draft, post: post, user: other_user)
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to be_empty
    end

    it "shows solo threads" do
      create(:reply, user: user, post: post)
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to match_array([post])
    end

    it "does not show top-posts by user" do
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to be_empty
    end
  end

  # TODO more tests
end
