RSpec.describe RepliesController, 'GET history' do
  let(:user) { create(:user) }
  let(:reply) { create(:reply, user: user) }

  it "requires valid reply" do
    get :history, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post access" do
    reply.post.update!(privacy: :private)
    reply.reload
    expect(reply.post.visible_to?(user)).to eq(false)

    login_as(user)
    get :history, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "works when logged out" do
    get :history, params: { id: reply.id }
    expect(response.status).to eq(200)
  end

  it "works for reader accounts" do
    login_as(create(:reader_user))
    get :history, params: { id: reply.id }
    expect(response).to have_http_status(200)
  end

  it "works when logged in" do
    login
    get :history, params: { id: reply.id }
    expect(response.status).to eq(200)
  end

  context "with views" do
    render_views

    after(:each) { Audited.auditing_enabled = false }

    it "works", versioning: true do
      Version.as_user(user) do
        reply
        reply.update!(content: 'new content', paper_trail_event: 'update')
        reply.update!(character: create(:character, user: user), paper_trail_event: 'update')
      end
      expect(reply.versions.last.event).to eq('update')

      get :history, params: { id: reply.id }
      expect(response.status).to eq(200)
      expect(assigns(:versions)).to be_kind_of(ActiveRecord::Relation)
      expect(assigns(:versions).first).to be_kind_of(Version)
    end

    it "works with audits" do
      Audited.auditing_enabled = true
      Audited.audit_class.as_user(user) do
        reply.update!(content: 'new content')
        reply.update!(character: create(:character, user: user))
      end

      get :history, params: { id: reply.id }
      expect(response.status).to eq(200)
      expect(assigns(:versions)).to be_kind_of(ActiveRecord::Relation)
      expect(assigns(:versions).first).to be_kind_of(Audited::Audit)
      Audited.auditing_enabled = false
    end

    it "works with mixed audits and versions" do
      Audited.auditing_enabled = true
      Audited.audit_class.as_user(user) { reply.update!(content: 'new content') }
      Audited.auditing_enabled = false
      with_versioning do
        Version.as_user(user) { reply.update!(character: create(:character, user: user), paper_trail_event: 'update') }
      end
      expect(reply.versions.last.event).to eq('update')

      get :history, params: { id: reply.id }
      expect(response.status).to eq(200)
      expect(assigns(:versions)).to be_kind_of(Array)
      expect(assigns(:versions).first).to be_kind_of(Audited::Audit)
      expect(assigns(:versions).last).to be_kind_of(Version)
    end
  end
end
