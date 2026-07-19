RSpec.describe "Post" do
  describe "continuity-scoped display" do
    it "renders a post through a secondary continuity with its navigation" do
      user = create(:user, password: known_test_password)
      board = create(:board, creator: user, name: "Browsed Continuity")
      arc = create(:board_section, board: board, name: "Arc One")
      create(:post, user: user, board: board, section: arc, subject: "First Thread")
      shared = create(:post, user: user, board: create(:board, creator: user), subject: "Shared Thread", status: :complete)
      shared.post_boards.create!(board: board, section: arc)
      create(:post, user: user, board: board, section: arc, subject: "Third Thread")
      login(user)

      get "/boards/#{board.id}/posts/#{shared.id}"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Browsed Continuity")
        expect(response.body).to include("Arc One")
        expect(response.body).to include("Previous Post")
        expect(response.body).to include("Next Post")
        expect(response.body).to include("Here Ends This Thread")
      end
    end

    it "renders the post editor with its secondary memberships" do
      user = create(:user, password: known_test_password)
      board = create(:board, creator: user)
      other = create(:board, creator: user, name: "Second Home")
      section = create(:board_section, board: other, name: "Away Arc")
      plain = create(:board, creator: user, name: "Plain Home")
      target = create(:post, user: user, board: board)
      target.post_boards.create!(board: other, section: section)
      target.post_boards.create!(board: plain)
      login(user)

      get "/posts/#{target.id}/edit", params: { continuity_id: other.id }
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).to include("Other continuities")
        expect(response.body).to include("Second Home")
        expect(response.body).to include("Away Arc")
        expect(response.body).to include("Plain Home")
      end
    end
  end

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
