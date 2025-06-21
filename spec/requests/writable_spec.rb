RSpec.describe "Writable" do
  describe "creation" do
    it "creates a new post and reply and edits them with history" do
      user = create(:user, username: "John Doe", password: known_test_password)
      login(user)

      board = create(:board)

      # create post
      get "/posts/new"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Create a new post")
      end

      expect {
        post "/posts", params: {
          post: {
            subject: "Temp post",
            content: "Post text",
            board_id: board.id,
          },
        }
      }.to change { Post.count }.by(1)
      target = Post.last

      aggregate_failures do
        expect(response).to redirect_to(post_path(target))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Post created.")
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Temp post")
        expect(response.body).to include("Post text")
        expect(response.body).to include("John Doe")
      end

      # edit post
      get "/posts/#{target.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit post")
      end

      patch "/posts/#{target.id}", params: {
        post: {
          content: "Edited post text",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(post_path(target))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Post updated.")
        expect(target.reload.content).to eq("Edited post text")
      end
      follow_redirect!

      expect(response.body).to include("See History")

      # view post history
      get "/posts/#{target.id}/history"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:history)
        expect(response.body).to include("Edit History")
        expect(response.body).to include("Post text")
        expect(response.body).to include("Edited post text")
      end

      # create reply
      expect {
        post "/replies", params: {
          reply: {
            post_id: target.id,
            content: "Sample text",
          },
        }
      }.to change { Reply.count }.by(1)
      reply = Reply.last

      aggregate_failures do
        expect(response).to redirect_to(reply_path(reply, anchor: "reply-#{reply.id}"))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Reply posted.")
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:show)
        expect(response.body).to include("Temp post")
        expect(response.body).to include("Sample text")
      end

      # edit reply
      get "/replies/#{reply.id}/edit"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:edit)
        expect(response.body).to include("Edit reply")
      end

      patch "/replies/#{reply.id}", params: {
        reply: {
          content: "Edited text",
        },
      }
      aggregate_failures do
        expect(response).to redirect_to(reply_path(reply, anchor: "reply-#{reply.id}"))
        expect(flash[:error]).to be_nil
        expect(flash[:success]).to eq("Reply updated.")
        expect(reply.reload.content).to eq("Edited text")
      end
      follow_redirect!

      expect(response.body).to match(/See History.*See History/m)

      # view reply history
      get "/replies/#{reply.id}/history"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:history)
        expect(response.body).to include("Edit History")
        expect(response.body).to include("Sample text")
        expect(response.body).to include("Edited text")
      end
    end

    it "renders the post import page", :aggregate_failures do
      user = create(:importing_user, password: known_test_password)
      login(user)

      get "/posts/new?view=import"

      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
      expect(response.body).to include("Import a post")
    end
  end
end
