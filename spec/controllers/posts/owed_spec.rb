RSpec.describe PostsController, 'GET owed' do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post) { create(:post, user: user) }

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

  context "with views" do
    render_views

    before(:each) do
      login_as(user)
      create(:reply, post: post)
      post.mark_read(user)
    end

    it "succeeds" do
      get :owed
      expect(response.status).to eq(200)
      expect(response.body).to include('note_go_strong')
    end

    it "succeeds with dark" do
      user.update!(layout: 'starrydark')
      get :owed
      expect(response.status).to eq(200)
      expect(response.body).to include('bullet_go_strong')
    end
  end

  context "with hidden" do
    let(:hidden_post) { create(:post, user: user) }

    before(:each) do
      login_as(user)
      create(:reply, post: post)
      create(:reply, post: hidden_post)
      hidden_post.opt_out_of_owed(user)
    end

    it "does not show hidden without arg" do
      get :owed
      expect(assigns(:posts)).to eq([post])
    end

    it "shows only hidden with arg" do
      get :owed, params: { view: 'hidden' }
      expect(assigns(:posts)).to eq([hidden_post])
    end
  end

  context "with hiatused" do
    before(:each) do
      login_as(user)
      create(:post)
    end

    it "shows hiatused posts" do
      create(:reply, post: post, user: other_user)
      post.update!(status: :hiatus)

      get :owed, params: { view: 'hiatused' }
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to eq([post])
    end

    it "shows auto-hiatused posts" do
      Timecop.freeze(1.month.ago) do
        create(:reply, post: post, user: other_user) # post is initialized in the timecop block as well
      end
      get :owed, params: { view: 'hiatused' }
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to eq([post])
    end
  end

  context "with posts" do
    before(:each) do
      other_user
      login_as(user)
    end

    context "with coauther reply" do
      before(:each) { create(:reply, post: post, user: other_user) }

      it "shows a post if replied to by someone else" do
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to match_array([post])
      end

      it "does not show posts from site_testing" do
        post.update!(board: create(:board, id: Board::ID_SITETESTING))

        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to be_empty
      end

      it "hides completed threads" do
        post.update!(status: :complete)
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to be_empty
      end

      it "hides abandoned threads" do
        post.update!(status: :abandoned)
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to be_empty
      end

      it "show hiatused threads by default" do
        post.update!(status: :hiatus)

        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to match_array([post])
      end

      it "optionally hides hiatused threads" do
        post.update!(status: :hiatus)
        user.update!(hide_hiatused_tags_owed: true)

        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to be_empty
      end

      it "hides threads the user has manually removed themselves from" do
        post.opt_out_of_owed(user)
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to be_empty
      end

      it "lists number of posts in the title" do
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:page_title)).to eq('[1] Replies Owed')
      end
    end

    context "with own reply" do
      before(:each) do
        create(:reply, post: post, user: other_user)
        create(:reply, post: post, user: user)
      end

      it "hides a post if you reply to it" do
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts).count).to eq(0)
      end

      it "shows threads with existing drafts" do
        create(:reply_draft, post: post, user: user)
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to match_array([post])
      end

      it "does not show threads with drafts by coauthors" do
        create(:reply_draft, post: post, user: other_user)
        get :owed
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to be_empty
      end
    end

    it "shows threads the user has been invited to" do
      post = create(:post, user: other_user, unjoined_authors: [user])
      get :owed
      expect(response.status).to eq(200)
      expect(assigns(:posts)).to match_array([post])
    end

    it "orders posts by tagged_at" do
      post2 = create(:post, user: user)
      post3 = create(:post, user: user)
      post1 = create(:post, user: user)
      create(:reply, post: post3, user: other_user)
      create(:reply, post: post2, user: other_user)
      create(:reply, post: post1, user: other_user)
      get :owed
      expect(assigns(:posts)).to eq([post1, post2, post3])
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
