RSpec.describe "Post" do
  describe "hidden list" do
    it "shows hidden posts" do
      user = login
      create(:post, subject: "Shown post")
      hidden = create(:post, subject: "Hidden post")
      hidden.ignore(user)

      get "/posts/hidden"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:hidden)
        expect(response.body).to include("Hidden from Unread")
        expect(response.body).to include("Hidden post")
        expect(response.body).not_to include("Shown post")
      end
    end
  end

  describe "audit history" do
    it "shows audit history" do
      user = create(:user, username: "John Doe", password: known_test_password)
      login(user)
      target = create(:post, user: user, subject: "Shown post")
      reply = create(:reply, user: user, post: target, content: "Test content")

      delete "/replies/#{reply.id}"
      aggregate_failures do
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(post_path(target, page: 1))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Reply deleted.")
      end

      get "/posts/#{target.id}/delete_history"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:delete_history)
        expect(response.body).to include("History of Deleted Replies")
        expect(response.body).to match(/Reply deleted.*by.*John Doe/m)
        expect(response.body).to include("Test content")
      end
    end
  end
end
