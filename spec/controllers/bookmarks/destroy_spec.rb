RSpec.describe BookmarksController, 'DELETE destroy' do
  let(:user) { create(:user, public_bookmarks: true) }
  let(:reply) { create(:reply) }
  let(:bookmark) { create(:bookmark, user: user, reply: reply) }

  it "requires login" do
    delete :destroy, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires valid bookmark" do
    login
    delete :destroy, params: { id: -1 }
    expect(response).to redirect_to(posts_path)
    expect(flash[:error]).to eq("Bookmark could not be found.")
  end

  it "requires visible reply" do
    reply.post.update!(privacy: :access_list, viewers: [reply.user])
    login
    delete :destroy, params: { id: bookmark.id }
    expect(response).to redirect_to(posts_path)
    expect(flash[:error]).to eq("Bookmark could not be found.")
  end

  it "requires bookmark ownership" do
    login
    delete :destroy, params: { id: bookmark.id }
    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:error]).to eq("You do not have permission to perform this action.")
  end

  it "succeeds for bookmark owner" do
    login_as(user)
    delete :destroy, params: { id: bookmark.id }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:success]).to eq("Bookmark removed.")
    expect(Bookmark.find_by_id(bookmark.id)).to be_nil
  end

  it "handles destroy failure" do
    login_as(user)

    allow(Bookmark).to receive(:find_by).and_call_original
    allow(Bookmark).to receive(:find_by).with({ id: bookmark.id.to_s }).and_return(bookmark)
    allow(bookmark).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
    expect(bookmark).to receive(:destroy!)

    delete :destroy, params: { id: bookmark.id }

    expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
    expect(flash[:error]).to eq("Bookmark could not be deleted.")
    expect(Bookmark.order(:id).last).to eq(bookmark)
  end
end
