RSpec.describe BookmarksController do
  describe "GET search" do
    it "renders search page without params" do
      get :search
      expect(response).to have_http_status(:ok)
      expect(assigns(:page_title)).to eq('Search Bookmarks')
    end

    it "returns without searching when no commit" do
      get :search
      expect(assigns(:search_results)).to be_nil
    end

    it "returns without searching when user not found" do
      get :search, params: { commit: true, user_id: -1 }
      expect(assigns(:search_results)).to be_nil
    end

    it "returns empty results when bookmarks are private" do
      user = create(:user, public_bookmarks: false)
      other = create(:user)
      login_as(other)
      get :search, params: { commit: true, user_id: user.id }
      expect(assigns(:search_results)).to be_empty
    end

    it "returns bookmarks for user with public bookmarks" do
      user = create(:user, public_bookmarks: true)
      reply = create(:reply)
      Bookmark.create!(user: user, reply: reply, post: reply.post, type: 'reply_bookmark')
      get :search, params: { commit: true, user_id: user.id }
      expect(assigns(:search_results)).to be_present
    end

    it "filters by post_id" do
      user = create(:user, public_bookmarks: true)
      reply = create(:reply)
      Bookmark.create!(user: user, reply: reply, post: reply.post, type: 'reply_bookmark')
      other_reply = create(:reply)
      Bookmark.create!(user: user, reply: other_reply, post: other_reply.post, type: 'reply_bookmark')
      get :search, params: { commit: true, user_id: user.id, post_id: reply.post_id }
      expect(assigns(:search_results).map(&:id)).to include(reply.id)
      expect(assigns(:search_results).map(&:id)).not_to include(other_reply.id)
    end

    it "returns own bookmarks when logged in" do
      user = create(:user, public_bookmarks: false)
      reply = create(:reply)
      Bookmark.create!(user: user, reply: reply, post: reply.post, type: 'reply_bookmark')
      login_as(user)
      get :search, params: { commit: true, user_id: user.id }
      expect(assigns(:search_results)).to be_present
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires at_id" do
      user = create(:user)
      login_as(user)
      post :create
      expect(flash[:error]).to eq("Reply not selected.")
      expect(response).to redirect_to(posts_path)
    end

    it "requires valid reply" do
      user = create(:user)
      login_as(user)
      post :create, params: { at_id: -1 }
      expect(flash[:error]).to eq("Reply not found.")
      expect(response).to redirect_to(posts_path)
    end

    it "creates a new bookmark" do
      user = create(:user)
      reply = create(:reply)
      login_as(user)
      expect {
        post :create, params: { at_id: reply.id }
      }.to change { Bookmark.count }.by(1)
      expect(flash[:success]).to eq("Bookmark added.")
    end

    it "does not duplicate bookmarks" do
      user = create(:user)
      reply = create(:reply)
      Bookmark.create!(user: user, reply: reply, post: reply.post, type: 'reply_bookmark')
      login_as(user)
      expect {
        post :create, params: { at_id: reply.id }
      }.not_to change { Bookmark.count }
      expect(flash[:error]).to eq("Bookmark already exists.")
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid bookmark" do
      user = create(:user)
      login_as(user)
      delete :destroy, params: { id: -1 }
      expect(flash[:error]).to eq("Bookmark could not be found.")
      expect(response).to redirect_to(posts_path)
    end

    it "requires ownership" do
      user = create(:user)
      other = create(:user)
      reply = create(:reply)
      bookmark = Bookmark.create!(user: other, reply: reply, post: reply.post, type: 'reply_bookmark', public: true)
      login_as(user)
      delete :destroy, params: { id: bookmark.id }
      expect(flash[:error]).to eq("You do not have permission to perform this action.")
    end

    it "destroys own bookmark" do
      user = create(:user)
      reply = create(:reply)
      bookmark = Bookmark.create!(user: user, reply: reply, post: reply.post, type: 'reply_bookmark')
      login_as(user)
      expect {
        delete :destroy, params: { id: bookmark.id }
      }.to change { Bookmark.count }.by(-1)
      expect(flash[:success]).to eq("Bookmark removed.")
    end
  end
end
