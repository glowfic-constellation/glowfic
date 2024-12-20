RSpec.describe Api::V1::BookmarksController do
  describe "PATCH update" do
    it "requires login", :show_in_doc do
      patch :update, params: { id: 0 }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires valid bookmark", :show_in_doc do
      api_login
      patch :update, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Bookmark could not be found.")
    end

    it "requires visible bookmark", :show_in_doc do
      api_login
      reply = create(:reply)
      bookmark = create(:bookmark, reply: reply, post: reply.post)
      reply.post.update!(privacy: :private)
      patch :update, params: { id: bookmark.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "requires name param", :show_in_doc do
      api_login
      reply = create(:reply)
      bookmark = create(:bookmark, reply: reply, post: reply.post)
      bookmark.user.update!(public_bookmarks: true)
      patch :update, params: { id: bookmark.id }
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq("Missing parameter name")
    end

    it "requires ownership of bookmark", :show_in_doc do
      api_login
      reply = create(:reply)
      bookmark = create(:bookmark, reply: reply, post: reply.post)
      bookmark.user.update!(public_bookmarks: true)
      patch :update, params: { id: bookmark.id, name: "New" }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    # TODO
    # it "handles failed saves" do
    #   user = api_login
    #   reply = create(:reply)
    #   bookmark = create(:bookmark, reply: reply, post: reply.post, user: user)
    #   allow(Bookmark).to receive(:update).and_return(false)
    #   # expect(bookmark).to receive(:update)

    #   # post = create(:post, user: user)
    #   # author = post.author_for(user)

    #   # allow(Post).to receive(:find_by).and_call_original
    #   # allow(Post).to receive(:find_by).with({ id: post.id.to_s }).and_return(post)
    #   # allow(post).to receive(:author_for).with(user).and_return(author)
    #   # allow(author).to receive(:update).and_return(false)
    #   # expect(author).to receive(:update)

    #   patch :update, params: { id: bookmark.id, name: 'New name' }

    #   expect(response).to have_http_status(422)
    #   expect(response.parsed_body['errors'][0]['message']).to eq('Post could not be updated.')
    # end

    it "succeeds with valid bookmark", :show_in_doc do
      user = api_login
      reply = create(:reply)
      bookmark = create(:bookmark, reply: reply, post: reply.post, user: user)
      expect(bookmark.name).to be_nil

      patch :update, params: { id: bookmark.id, name: "New name" }

      expect(response).to have_http_status(200)
      expect(response.parsed_body['name']).to eq("<p>New name</p>")
      bookmark.reload
      expect(bookmark.name).to eq('New name')
    end

    it "accepts blank name", :show_in_doc do
      user = api_login
      reply = create(:reply)
      bookmark = create(:bookmark, reply: reply, post: reply.post, user: user, name: "Old name")

      patch :update, params: { id: bookmark.id, name: "" }

      expect(response).to have_http_status(200)
      expect(response.parsed_body['name']).to eq("<p></p>")
      bookmark.reload
      expect(bookmark.name).to eq('')
    end
  end
end
