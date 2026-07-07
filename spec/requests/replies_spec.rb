RSpec.describe "Reply" do
  describe "edit form" do
    it "carries the continuity being viewed" do
      user = create(:user, password: known_test_password)
      reply = create(:reply, user: user)
      board = create(:board)
      reply.post.post_boards.create!(board: board)
      login(user)

      get "/replies/#{reply.id}/edit", params: { continuity_id: board.id }
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).to include('name="continuity_id"')
        expect(response.body).to include("value=\"#{board.id}\"")
      end
    end
  end

  describe "search" do
    it "works" do
      create(:reply, content: "Sample reply")
      create(:reply, content: "Other reply")

      get "/replies/search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Replies")
      end

      get "/replies/search?subj_content=Sample&commit=Search"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("Search Replies")
        expect(response.body).to include("<b>Sample</b> reply")
        expect(response.body).not_to include("Other")
      end
    end

    it "works with invalid post" do
      private_post = create(:post, privacy: :private)

      get "/replies/search?post_id=#{private_post.id}&commit=Search"

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:search)
        expect(response.body).to include("You do not have permission to view this post.")
      end
    end
  end
end
