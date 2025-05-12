RSpec.describe PostsController, 'GET index' do
  let(:controller_action) { "index" }
  let(:params) { {} }
  let(:assign_variable) { :posts }

  it "has a 200 status code" do
    get :index
    expect(response.status).to eq(200)
  end

  it "works for reader account" do
    login_as(create(:reader_user))
    get :index
    expect(response).to have_http_status(200)
  end

  it "paginates" do
    create_list(:post, 26)
    get :index
    expect(assigns(:posts).total_pages).to eq(2)
  end

  it "only fetches most recent threads" do
    create_list(:post, 26)
    oldest = Post.ordered_by_id.first
    get :index
    expect(assigns(:posts).map(&:id)).not_to include(oldest.id)
  end

  it "only fetches most recent threads based on updated_at" do
    create_list(:post, 26)
    oldest = Post.ordered_by_id.first
    next_oldest = Post.ordered_by_id.second
    oldest.update!(status: :complete)
    get :index
    ids_fetched = assigns(:posts).map(&:id)
    expect(ids_fetched.count).to eq(25)
    expect(ids_fetched).not_to include(next_oldest.id)
  end

  it "orders posts by tagged_at" do
    post2 = Timecop.freeze(8.minutes.ago) { create(:post) }
    post5 = Timecop.freeze(2.minutes.ago) { create(:post) }
    post1 = Timecop.freeze(10.minutes.ago) { create(:post) }
    post4 = Timecop.freeze(4.minutes.ago) { create(:post) }
    post3 = Timecop.freeze(6.minutes.ago) { create(:post) }
    get :index
    expect(assigns(:posts).map(&:id)).to eq([post5.id, post4.id, post3.id, post2.id, post1.id])
  end

  context "with views" do
    render_views

    it "sanitizes post descriptions" do
      create(:post, description: "<a href=\"/characters/1\">Name</a> and <a href=\"/characters/2\">Other Name</a> do a thing.")
      create(:post, description: "A & B do a thing")
      get :index
      expect(response.body).to include('title="Name and Other Name do a thing."')
      expect(response.body).to include('title="A &amp; B do a thing"')
    end
  end

  context "when logged out" do
    it_behaves_like "logged out post list"
  end

  context "when logged in" do
    it_behaves_like "logged in post list"

    context "with ignored posts" do
      let(:user) { create(:user) }
      let!(:posts) { create_list(:post, 3) }
      let(:ignored_post) { create(:post) }
      let(:ignored_board) { create(:board) }
      let(:ignored_board_post) { create(:post, board: ignored_board) }

      before(:each) do
        login_as(user)
        ignored_post.ignore(user)
        ignored_board.ignore(user)
      end

      it "does not hide posts with option disabled" do
        expected_post_ids = posts.map(&:id) + [ignored_post.id, ignored_board_post.id]
        get controller_action, params: params
        expect(response.status).to eq(200)
        expect(assigns(assign_variable).map(&:id)).to match_array(expected_post_ids)
      end

      it "hides posts with option enabled" do
        user.update!(hide_from_all: true)
        get controller_action, params: params
        expect(response.status).to eq(200)
        expect(assigns(assign_variable)).to match_array(posts)
      end
    end
  end
end
