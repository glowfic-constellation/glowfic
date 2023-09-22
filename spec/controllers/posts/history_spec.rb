RSpec.describe PostsController, 'GET history' do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }

  it "requires post" do
    login
    get :history, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "works logged out" do
    get :history, params: { id: post.id }
    expect(response.status).to eq(200)
  end

  it "works logged in" do
    login
    get :history, params: { id: post.id }
    expect(response.status).to eq(200)
  end

  it "works for reader account" do
    login_as(create(:reader_user))
    get :history, params: { id: post.id }
    expect(response).to have_http_status(200)
  end

  context "with render_view" do
    render_views

    before(:each) { login_as(user) }

    after(:each) { Audited.auditing_enabled = false }

    it "works", versioning: true do
      Version.as_user(user) do
        post.update!(privacy: :access_list)
        post.update!(board: create(:board))
        post.update!(content: 'new content')
      end

      get :history, params: { id: post.id }

      expect(response.status).to eq(200)
    end

    it "works with audits" do
      Audited.auditing_enabled = true
      Audited.audit_class.as_user(user) do
        post.update!(privacy: :access_list)
        post.update!(board: create(:board))
        post.update!(content: 'new content')
      end

      get :history, params: { id: post.id }
      expect(response.status).to eq(200)
      expect(assigns(:versions)).to be_a(ActiveRecord::Relation)
      expect(assigns(:versions).first).to be_a(Audited::Audit)
    end

    it "works with mixed audits and versions" do
      Audited.auditing_enabled = true
      Audited.audit_class.as_user(user) do
        post.update!(privacy: :access_list)
        post.update!(board: create(:board))
      end
      Audited.auditing_enabled = false

      with_versioning do
        Version.as_user(user) { post.update!(content: 'new content') }
      end

      get :history, params: { id: post.id }
      expect(response.status).to eq(200)
      expect(assigns(:versions)).to be_a(Array)
      expect(assigns(:versions).first).to be_a(Audited::Audit)
      expect(assigns(:versions).last).to be_a(Version)
    end
  end
end
