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
    num_posts_fetched = controller.instance_variable_get(:@posts).total_pages
    expect(num_posts_fetched).to eq(2)
  end

  it "only fetches most recent threads" do
    create_list(:post, 26)
    oldest = Post.ordered_by_id.first
    get :index
    ids_fetched = controller.instance_variable_get(:@posts).map(&:id)
    expect(ids_fetched).not_to include(oldest.id)
  end

  it "only fetches most recent threads based on updated_at" do
    create_list(:post, 26)
    oldest = Post.ordered_by_id.first
    next_oldest = Post.ordered_by_id.second
    oldest.update!(status: :complete)
    get :index
    ids_fetched = controller.instance_variable_get(:@posts).map(&:id)
    expect(ids_fetched.count).to eq(25)
    expect(ids_fetched).not_to include(next_oldest.id)
  end

  it "orders posts by tagged_at" do
    post2 = Timecop.freeze(Time.zone.now - 8.minutes) { create(:post) }
    post5 = Timecop.freeze(Time.zone.now - 2.minutes) { create(:post) }
    post1 = Timecop.freeze(Time.zone.now - 10.minutes) { create(:post) }
    post4 = Timecop.freeze(Time.zone.now - 4.minutes) { create(:post) }
    post3 = Timecop.freeze(Time.zone.now - 6.minutes) { create(:post) }
    get :index
    ids_fetched = controller.instance_variable_get(:@posts).map(&:id)
    expect(ids_fetched).to eq([post5.id, post4.id, post3.id, post2.id, post1.id])
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
    include_examples "logged out post list"
  end

  context "when logged in" do
    include_examples "logged in post list"
  end
end
