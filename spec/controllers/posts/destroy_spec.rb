RSpec.describe PostsController, 'DELETE destroy' do
  let(:user) { create(:user) }
  let(:post) { create(:post, user: user) }

  it "requires login" do
    delete :destroy, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create replies"
  end

  it "requires valid post" do
    login
    delete :destroy, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post permission" do
    login
    delete :destroy, params: { id: post.id }
    expect(response).to redirect_to(post_url(post))
    expect(flash[:error]).to eq("You do not have permission to modify this post.")
  end

  it "succeeds" do
    login_as(user)
    delete :destroy, params: { id: post.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:success]).to eq("Post deleted.")
  end

  it "deletes Post::Authors" do
    login_as(user)
    other_user = create(:user)
    post = create(:post, user: user, authors: [user, other_user])
    id1 = post.post_authors[0].id
    id2 = post.post_authors[1].id
    delete :destroy, params: { id: post.id }
    expect(Post::Author.find_by(id: id1)).to be_nil
    expect(Post::Author.find_by(id: id2)).to be_nil
  end

  it "handles destroy failure" do
    reply = create(:reply, user: post.user, post: post)
    login_as(user)

    allow(Post).to receive(:find_by).and_call_original
    allow(Post).to receive(:find_by).with({ id: post.id.to_s }).and_return(post)
    allow(post).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
    expect(post).to receive(:destroy!)

    delete :destroy, params: { id: post.id }

    expect(response).to redirect_to(post_url(post))
    expect(flash[:error]).to eq("Post could not be deleted.")
    expect(reply.reload.post).to eq(post)
  end
end
