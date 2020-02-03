RSpec.describe RepliesController, 'DELETE destroy' do
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
    reply = create(:reply)
    expect(reply.user_id).not_to eq(reply.post.user_id)
    expect(reply.post.visible_to?(reply.user)).to eq(true)

    reply.post.update!(privacy: :private)
    reply.reload
    expect(reply.post.visible_to?(reply.user)).to eq(false)

    login_as(reply.user)
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "requires reply access" do
    reply = create(:reply)
    login
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(post_url(reply.post))
    expect(flash[:error]).to eq("You do not have permission to modify this reply.")
  end

  it "succeeds for reply creator" do
    reply = create(:reply)
    login_as(reply.user)
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(post_url(reply.post, page: 1))
    expect(flash[:success]).to eq("Reply deleted.")
    expect(Reply.find_by_id(reply.id)).to be_nil
  end

  it "succeeds for admin user" do
    reply = create(:reply)
    login_as(create(:admin_user))
    delete :destroy, params: { id: reply.id }
    expect(response).to redirect_to(post_url(reply.post, page: 1))
    expect(flash[:success]).to eq("Reply deleted.")
    expect(Reply.find_by_id(reply.id)).to be_nil
  end

  it "respects per_page when redirecting" do
    reply = create(:reply) # p1
    reply = create(:reply, post: reply.post, user: reply.user) # p1
    reply = create(:reply, post: reply.post, user: reply.user) # p2
    reply = create(:reply, post: reply.post, user: reply.user) # p2
    login_as(reply.user)
    delete :destroy, params: { id: reply.id, per_page: 2 }
    expect(response).to redirect_to(post_url(reply.post, page: 2))
  end

  it "respects per_page when redirecting first on page" do
    reply = create(:reply) # p1
    reply = create(:reply, post: reply.post, user: reply.user) # p1
    reply = create(:reply, post: reply.post, user: reply.user) # p2
    reply = create(:reply, post: reply.post, user: reply.user) # p2
    reply = create(:reply, post: reply.post, user: reply.user) # p3
    login_as(reply.user)
    delete :destroy, params: { id: reply.id, per_page: 2 }
    expect(response).to redirect_to(post_url(reply.post, page: 2))
  end

  it "deletes post author on deleting only reply in open posts" do
    user = create(:user)
    post = create(:post)
    expect(post.authors_locked).to eq(false)
    login_as(user)
    reply = create(:reply, post: post, user: user)
    post_user = post.post_authors.find_by(user: user)
    id = post_user.id
    expect(post_user.joined).to eq(true)
    delete :destroy, params: { id: reply.id }
    expect(Post::Author.find_by(id: id)).to be_nil
  end

  it "sets joined to false on deleting only reply when invited" do
    user = create(:user)
    other_user = create(:user)
    post = create(:post, user: other_user, authors: [user, other_user], authors_locked: true)
    expect(post.authors_locked).to eq(true)
    expect(post.post_authors.find_by(user: user)).not_to be_nil
    login_as(user)
    reply = create(:reply, post: post, user: user)
    post_user = post.post_authors.find_by(user: user)
    expect(post_user.joined).to eq(true)
    delete :destroy, params: { id: reply.id }
    post_user.reload
    expect(post_user.joined).to eq(false)
  end

  it "does not clean up post author when other replies exist" do
    user = create(:user)
    post = create(:post)
    expect(post.authors_locked).to eq(false)
    login_as(user)
    create(:reply, post: post, user: user) # remaining reply
    reply = create(:reply, post: post, user: user)
    post_user = post.post_authors.find_by(user: user)
    expect(post_user.joined).to eq(true)
    delete :destroy, params: { id: reply.id }
    post_user.reload
    expect(post_user.joined).to eq(true)
  end

  it "handles destroy failure" do
    post = create(:post)
    reply = create(:reply, user: post.user, post: post)
    login_as(post.user)

    allow(Reply).to receive(:find_by).and_call_original
    allow(Reply).to receive(:find_by).with({ id: reply.id.to_s }).and_return(reply)
    allow(reply).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
    expect(reply).to receive(:destroy!)

    delete :destroy, params: { id: reply.id }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:error]).to eq("Reply could not be deleted.")
    expect(post.reload.replies).to eq([reply])
  end
end
