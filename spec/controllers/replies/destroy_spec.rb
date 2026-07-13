RSpec.describe RepliesController, 'DELETE destroy' do
  let(:user) { create(:user) }
  let(:post) { create(:post) }
  let(:reply) { create(:reply, post: post, user: user) }

  it "requires login" do
    delete :destroy, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create replies"
  end

  it "requires valid reply" do
    login
    delete :destroy, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post access" do
    post.update!(privacy: :private)
    expect(post.reload.visible_to?(user)).to eq(false)

    login_as(user)
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "requires reply access" do
    login
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(post_url(post))
    expect(flash[:error]).to eq("You do not have permission to modify this reply.")
  end

  it "succeeds for reply creator" do
    login_as(user)
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(post_url(reply.post, page: 1))
    expect(flash[:success]).to eq("Reply deleted.")
    expect(Reply.find_by(id: reply.id)).to be_nil
  end

  it "succeeds for admin user" do
    login_as(create(:admin_user))
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(post_url(reply.post, page: 1))
    expect(flash[:success]).to eq("Reply deleted.")
    expect(Reply.find_by(id: reply.id)).to be_nil
  end

  it "respects per_page when redirecting" do
    create_list(:reply, 3, post: post, user: user)
    reply
    login_as(user)
    delete :destroy, params: { id: reply.id, per_page: 2 }
    expect(response).to redirect_to(post_url(reply.post, page: 2))
  end

  it "respects per_page when redirecting first on page" do
    create_list(:reply, 4, post: post, user: user)
    reply
    login_as(user)
    delete :destroy, params: { id: reply.id, per_page: 2 }
    expect(response).to redirect_to(post_url(reply.post, page: 2))
  end

  it "deletes post author on deleting only reply in open posts" do
    login_as(user)
    reply
    post_user = post.post_authors.find_by(user: user)
    expect(post_user.joined).to eq(true)
    delete :destroy, params: { id: reply.id }
    expect(Post::Author.find_by(id: post_user.id)).to be_nil
  end

  it "sets joined to false on deleting only reply when invited" do
    other_user = post.user
    post.update!(authors: [user, other_user], authors_locked: true)
    login_as(user)

    reply
    post_user = post.post_authors.find_by(user: user)
    expect(post_user.joined).to eq(true)

    delete :destroy, params: { id: reply.id }

    expect(post_user.reload.joined).to eq(false)
  end

  it "does not clean up post author when other replies exist" do
    login_as(user)
    create(:reply, post: post, user: user) # remaining reply
    reply
    post_user = post.post_authors.find_by(user: user)
    expect(post_user.joined).to eq(true)
    delete :destroy, params: { id: reply.id }
    expect(post_user.reload.joined).to eq(true)
  end

  it "handles destroy failure" do
    login_as(user)

    allow(Reply).to receive(:find_by).and_call_original
    allow(Reply).to receive(:find_by).with({ id: reply.id.to_s }).and_return(reply)
    allow(reply).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
    expect(reply).to receive(:destroy!)

    delete :destroy, params: { id: reply.id }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:error]).to eq("Reply could not be deleted.")
    expect(post.reload.replies).to eq([reply])
  end

  context "reorders" do
    let!(:reply) { create(:reply, user: user, post: post) }
    let!(:replies) { Reply.where(id: create_list(:reply, 2, post: post).map(&:id)) }
    let!(:order) { replies.map(&:reply_order) }

    before(:each) { login_as(user) }

    it "correctly" do
      delete :destroy, params: { id: reply.id }

      expect(flash[:success]).to eq("Reply deleted.")
      expect(replies.reload.map(&:reply_order)).to eq(order.map { it - 1 })
    end

    it "correctly without a written" do
      post.written.delete
      expect(replies.reload.map(&:reply_order)).to eq(order)

      delete :destroy, params: { id: reply.id }

      expect(flash[:success]).to eq("Reply deleted.")
      expect(replies.reload.map(&:reply_order)).to eq(order.map { it - 1 })
    end
  end
end
