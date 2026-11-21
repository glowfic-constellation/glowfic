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

  describe "API lists" do
    let(:board) { create(:board) }
    let(:add_post) do
      lambda do
        post = create(:post, board: board, unjoined_authors: [create(:user)])
        create_list(:reply, 2, post: post)
      end
    end

    before(:each) { add_post.call }

    it "does not run a query per post on /api/v1/posts" do
      expect_constant_queries("/api/v1/posts") { 2.times { add_post.call } }
      expect(response.parsed_body['results'].size).to eq(3)
      expect(response.parsed_body['results'].pluck('num_replies')).to all(eq(2))
    end

    it "does not run a query per post on /api/v1/boards/:id/posts" do
      expect_constant_queries("/api/v1/boards/#{board.id}/posts") { 2.times { add_post.call } }
      expect(response.parsed_body['results'].size).to eq(3)
    end

    it "does not run a query per post on /api/v1/users/:id/posts" do
      user = create(:user)
      add_user_post = -> { create(:post, user: user, board: board, unjoined_authors: [create(:user)]) }
      add_user_post.call
      expect_constant_queries("/api/v1/users/#{user.id}/posts") { 2.times { add_user_post.call } }
      expect(response.parsed_body['results'].size).to eq(3)
    end
  end
end
