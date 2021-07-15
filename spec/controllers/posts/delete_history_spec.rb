RSpec.describe PostsController, 'GET delete_history', versioning: true do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }

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
    get :delete_history, params: { id: post.id }
    expect(response).to redirect_to(post_url(post))
    expect(flash[:error]).to eq("You do not have permission to modify this post.")
  end

  context "load history" do
    let!(:reply) { create(:reply, post: post, content: 'old content') }

    before(:each) do
      login_as(user)
      reply.destroy!
    end

    it "sets correct variables" do
      get :delete_history, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:audit).auditable_id).to eq(reply.id)
    end

    it "ignores restored replies" do
      restore(reply)
      get :delete_history, params: { id: post.id }
      expect(assigns(:deleted_audits).count).to eq(0)
    end

    it "only selects more recent restore" do
      id = reply.id
      restore(reply)
      reply = Reply.find_by_id(id)
      reply.update!(content: 'new content')
      reply.destroy!
      get :delete_history, params: { id: post.id }
      expect(assigns(:deleted_audits).count).to eq(1)
      expect(assigns(:audit).object_changes['content']).to eq('new content')
    end
  end

  def restore(reply)
    audit = Reply::Version.where(event: 'destroy', item_id: reply.id).last
    new_reply = audit.reify
    new_reply.is_import = true
    new_reply.skip_notify = true
    new_reply.id = audit.item_id
    new_reply.save!
  end
end
