RSpec.describe PostsController, 'GET delete_history' do
  before(:each) { Reply.auditing_enabled = true }

  after(:each) { Reply.auditing_enabled = false }

  it "requires login" do
    get :delete_history, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create posts"
  end

  it "requires post" do
    login
    get :delete_history, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires permission" do
    login
    post = create(:post)
    get :delete_history, params: { id: post.id }
    expect(response).to redirect_to(post_url(post))
    expect(flash[:error]).to eq("You do not have permission to modify this post.")
  end

  it "sets correct variables" do
    post = create(:post)
    login_as(post.user)
    reply = create(:reply, post: post, user: post.user)
    reply.destroy!
    get :delete_history, params: { id: post.id }
    expect(response).to have_http_status(200)
    expect(assigns(:audit).auditable_id).to eq(reply.id)
  end

  it "ignores restored replies" do
    post = create(:post)
    login_as(post.user)
    reply = create(:reply, post: post, user: post.user)
    reply.destroy!
    restore(reply)
    get :delete_history, params: { id: post.id }
    expect(assigns(:deleted_audits).count).to eq(0)
  end

  it "only selects more recent restore" do
    post = create(:post)
    login_as(post.user)
    reply = create(:reply, post: post, user: post.user, content: 'old content')
    reply.destroy!
    restore(reply)
    reply = Reply.find_by_id(reply.id)
    reply.content = 'new content'
    reply.save!
    reply.destroy!
    get :delete_history, params: { id: post.id }
    expect(assigns(:deleted_audits).count).to eq(1)
    expect(assigns(:audit).audited_changes['content']).to eq('new content')
  end

  def restore(reply)
    audit = Audited::Audit.where(action: 'destroy', auditable_id: reply.id).last
    new_reply = Reply.new(audit.audited_changes)
    new_reply.is_import = true
    new_reply.skip_notify = true
    new_reply.id = audit.auditable_id
    new_reply.save!
  end
end
