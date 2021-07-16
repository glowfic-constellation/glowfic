RSpec.describe PostsController, 'GET delete_history' do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }
  let(:reply) { create(:reply, post: post, content: 'old content') }

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

  context "with only versions", versioning: true do
    before(:each) { login_as(user) }

    it "sets correct variables" do
      Version.as_user(reply.user) { reply.destroy! }
      get :delete_history, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:audit).item_id).to eq(reply.id)
    end

    it "ignores restored replies" do
      Version.as_user(reply.user) { reply.destroy! }
      restore(reply)
      get :delete_history, params: { id: post.id }
      expect(assigns(:deleted_audits)).to be_empty
    end

    it "only selects more recent restore" do
      Version.as_user(reply.user) { reply.destroy! }
      restore(reply)
      reply = Reply.find_by_id(reply.id)
      reply.update!(content: 'new content')
      Version.as_user(reply.user) { reply.destroy! }
      get :delete_history, params: { id: post.id }
      expect(assigns(:deleted_audits).size).to eq(1)
      expect(assigns(:audit).object_changes['content'][0]).to eq('new content')
    end

    it "paginates correctly" do
      replies = create_list(:reply, 20, post: post)
      deleted_replies = replies.select.with_index { |_, i| [0, 3, 6, 8, 10, 11, 15, 17, 18].include?(i) }
      deleted_ids = deleted_replies.map(&:id)
      deleted_replies.each { |reply| Version.as_user(reply.user) { reply.destroy! } }

      get :delete_history, params: { id: post.id, page: 5 }
      expect(assigns(:deleted_audits)).to be_kind_of(ActiveRecord::Relation)
      expect(assigns(:deleted_audits).total_pages).to eq(deleted_ids.size)
      expect(assigns(:deleted_audits).current_page).to eq(5)
      expect(assigns(:deleted).content).to eq(deleted_replies[4].content)
    end

    context "with views" do
      render_views

      it "works" do
        reply
        reply2 = create(:reply, user: user, post: post)
        Version.as_user(reply.user) { reply.destroy! }
        Version.as_user(user) { reply2.destroy! }
        get :delete_history, params: { id: post.id }
        expect(assigns(:deleted_audits).size).to eq(1)
      end
    end
  end

  context "with only audits" do
    before(:each) do
      Audited.auditing_enabled = true
      login_as(user)
    end

    after(:each) { Audited.auditing_enabled = false }

    it "sets correct variables" do
      Audited.audit_class.as_user(reply.user) { reply.destroy! }
      get :delete_history, params: { id: post.id }
      expect(response).to have_http_status(200)
      expect(assigns(:audit).auditable_id).to eq(reply.id)
    end

    it "ignores restored replies" do
      Audited.audit_class.as_user(reply.user) { reply.destroy! }
      restore(reply)
      get :delete_history, params: { id: post.id }
      expect(assigns(:deleted_audits)).to be_empty
    end

    it "only selects more recent restore" do
      Audited.audit_class.as_user(reply.user) { reply.destroy! }
      restore(reply)
      reply = Reply.find_by_id(reply.id)
      reply.update!(content: 'new content')
      Audited.audit_class.as_user(reply.user) { reply.destroy! }
      get :delete_history, params: { id: post.id }
      expect(assigns(:deleted_audits).size).to eq(1)
      expect(assigns(:audit).audited_changes['content']).to eq('new content')
    end

    it "paginates correctly" do
      replies = create_list(:reply, 20, post: post)
      deleted_replies = replies.select.with_index { |_, i| [0, 3, 6, 8, 10, 11, 15, 17, 18].include?(i) }
      deleted_ids = deleted_replies.map(&:id)
      deleted_replies.each { |reply| Audited.audit_class.as_user(reply.user) { reply.destroy! } }

      get :delete_history, params: { id: post.id, page: 5 }
      expect(assigns(:deleted_audits)).to be_kind_of(ActiveRecord::Relation)
      expect(assigns(:deleted_audits).total_pages).to eq(deleted_ids.size)
      expect(assigns(:deleted_audits).current_page).to eq(5)
      expect(assigns(:deleted).content).to eq(deleted_replies[4].content)
    end

    context "with views" do
      render_views

      it "works" do
        reply2 = create(:reply, user: user, post: post)
        Audited.audit_class.as_user(reply.user) { reply.destroy! }
        Audited.audit_class.as_user(user) { reply2.destroy! }
        get :delete_history, params: { id: post.id }
        expect(assigns(:deleted_audits).size).to eq(1)
      end
    end
  end

  context "with mixed audits and versions" do
    before(:each) do
      Audited.auditing_enabled = true
      login_as(user)
    end

    after(:each) { Audited.auditing_enabled = false }

    it "paginates correctly" do
      replies = create_list(:reply, 20, post: post)
      deleted_replies = replies.select.with_index { |_, i| [0, 3, 6, 8, 10, 11, 15, 17, 18].include?(i) }
      deleted_ids = deleted_replies.map(&:id)
      deleted_replies[0..3].each { |reply| Audited.audit_class.as_user(reply.user) { reply.destroy! } }
      Audited.auditing_enabled = false

      with_versioning do
        deleted_replies[4..8].each { |reply| Version.as_user(reply.user) { reply.destroy! } }
        expect(Reply::Version.count).to eq(5)
      end

      get :delete_history, params: { id: post.id, page: 5 }
      expect(assigns(:deleted_audits)).to be_kind_of(Array)
      expect(assigns(:deleted_audits).total_pages).to eq(deleted_ids.size)
      expect(assigns(:deleted_audits).current_page).to eq(5)
      expect(assigns(:deleted).content).to eq(deleted_replies[4].content)
      expect(assigns(:audit)).to be_kind_of(Version)
      expect(assigns(:audit)).to eq(Reply::Version.find_by(item_id: deleted_ids[4], post_id: post.id, event: 'destroy'))
    end

    context "with views" do
      render_views

      it "works" do
        Audited.audit_class.as_user(reply.user) { reply.destroy! }
        Audited.auditing_enabled = false

        with_versioning do
          reply2 = create(:reply, user: user, post: post)
          Version.as_user(user) { reply2.destroy! }
        end
        get :delete_history, params: { id: post.id }
        expect(assigns(:deleted_audits).size).to eq(1)
      end
    end
  end

  def restore(reply)
    audit = Reply::Version.where(event: 'destroy', item_id: reply.id).last
    if audit
      new_reply = audit.reify
    else
      audit = Audited::Audit.where(action: 'destroy', auditable_id: reply.id).last
      new_reply = Reply.new(audit.audited_changes)
      new_reply.id = audit.auditable_id
    end
    new_reply.is_import = true
    new_reply.skip_notify = true
    new_reply.save!
  end
end
