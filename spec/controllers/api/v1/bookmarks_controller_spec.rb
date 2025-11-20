RSpec.describe Api::V1::BookmarksController do
  describe "POST create" do
    it "requires login", :show_in_doc do
      post :create
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires reply id", :show_in_doc do
      api_login
      post :create
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq("Missing parameter reply_id")
    end

    it "requires valid reply", :show_in_doc do
      api_login
      post :create, params: { reply_id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Reply could not be found.")
    end

    it "requires visible reply", :show_in_doc do
      api_login
      reply = create(:reply)
      reply.post.update!(privacy: :private)
      post :create, params: { reply_id: reply.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds with valid reply", :show_in_doc do
      user = api_login
      reply = create(:reply)

      post :create, params: { reply_id: reply.id }
      expect(response).to have_http_status(200)

      bookmark = Bookmark.find_by_id(response.parsed_body['id'])
      expect(bookmark.reply).to eq(reply)
      expect(bookmark.post).to eq(reply.post)
      expect(bookmark.user).to eq(user)
      expect(bookmark.type).to eq("reply_bookmark")
      expect(bookmark.name).to be_nil
      expect(bookmark.public).to be false
    end

    it "succeeds with name param", :show_in_doc do
      api_login
      reply = create(:reply)

      post :create, params: { reply_id: reply.id, name: "New Bookmark" }
      expect(response).to have_http_status(200)

      bookmark = Bookmark.find_by_id(response.parsed_body['id'])
      expect(bookmark.reply).to eq(reply)
      expect(bookmark.post).to eq(reply.post)
      expect(bookmark.name).to eq("New Bookmark")
      expect(bookmark.public).to be false
    end

    it "succeeds with public param", :show_in_doc do
      api_login
      reply = create(:reply)

      post :create, params: { reply_id: reply.id, public: true }
      expect(response).to have_http_status(200)

      bookmark = Bookmark.find_by_id(response.parsed_body['id'])
      expect(bookmark.reply).to eq(reply)
      expect(bookmark.post).to eq(reply.post)
      expect(bookmark.name).to be_nil
      expect(bookmark.public).to be true
    end

    it "succeeds with both params", :show_in_doc do
      api_login
      reply = create(:reply)

      post :create, params: { reply_id: reply.id, name: "New Bookmark", public: true }
      expect(response).to have_http_status(200)

      bookmark = Bookmark.find_by_id(response.parsed_body['id'])
      expect(bookmark.reply).to eq(reply)
      expect(bookmark.post).to eq(reply.post)
      expect(bookmark.name).to eq("New Bookmark")
      expect(bookmark.public).to be true
    end

    it "updates existing bookmark", :show_in_doc, aggregate_failures: false do
      user = api_login

      bookmark = create(:bookmark, user: user)
      expect(bookmark.name).to be_nil

      post :create, params: { reply_id: bookmark.reply.id, name: "New Name" }

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(Bookmark.find_by_id(bookmark.id).name).to eq("New Name")
      end
    end

    it "handles failed saves" do
      api_login
      reply = create(:reply)

      bookmarks = Bookmark.unscoped
      allow(Bookmark).to receive(:where).and_return(bookmarks)
      allow(bookmarks).to receive(:first_or_initialize).and_wrap_original do |m, *args|
        bookmark = m.call(*args)
        allow(bookmark).to receive(:save).and_return(false)
        expect(bookmark).to receive(:save)
        bookmark
      end

      post :create, params: { reply_id: reply.id }
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq('Bookmark could not be created.')
    end
  end

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

    it "requires visible post", :show_in_doc do
      api_login
      bookmark = create(:bookmark)
      bookmark.post.update!(privacy: :private)
      patch :update, params: { id: bookmark.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "requires ownership of bookmark", :show_in_doc do
      api_login
      bookmark = create(:bookmark)
      bookmark.user.update!(public_bookmarks: true)
      patch :update, params: { id: bookmark.id, name: "New" }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "handles failed saves" do
      user = api_login
      bookmark = create(:bookmark, user: user)

      allow(Bookmark).to receive(:find_by).and_call_original
      allow(Bookmark).to receive(:find_by).with({ id: bookmark.id.to_s }).and_return(bookmark)
      allow(bookmark).to receive(:update).and_return(false)
      expect(bookmark).to receive(:update)

      patch :update, params: { id: bookmark.id, name: 'New name' }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq('Bookmark could not be updated.')
    end

    it "Public bookmark doesn't override private post", :show_in_doc do
      user = api_login
      bookmark = create(:bookmark, user: user, public: true)
      bookmark.post.update!(privacy: :private)

      patch :update, params: { id: bookmark.id, name: "New name" }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds with only name", :show_in_doc, aggregate_failures: false do
      user = api_login
      bookmark = create(:bookmark, user: user)

      aggregate_failures do
        expect(bookmark.name).to be_nil
        expect(bookmark.public).to be(false)
      end

      patch :update, params: { id: bookmark.id, name: "New name" }
      bookmark.reload

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.parsed_body['name']).to eq("New name")
        expect(response.parsed_body['public']).to be(false)
        expect(bookmark.name).to eq('New name')
        expect(bookmark.public).to be(false)
      end
    end

    it "accepts blank name", :show_in_doc do
      user = api_login
      bookmark = create(:bookmark, user: user, name: "Old name")

      patch :update, params: { id: bookmark.id, name: "" }

      expect(response).to have_http_status(200)
      expect(response.parsed_body['name']).to eq("")
      bookmark.reload
      expect(bookmark.name).to eq('')
    end

    it "succeeds with only public", :show_in_doc, aggregate_failures: false do
      user = api_login
      bookmark = create(:bookmark, user: user, name: "Old name")

      aggregate_failures do
        expect(bookmark.name).to eq("Old name")
        expect(bookmark.public).to be(false)
      end

      patch :update, params: { id: bookmark.id, public: true }
      bookmark.reload

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.parsed_body['name']).to eq("Old name")
        expect(response.parsed_body['public']).to be true
        expect(bookmark.name).to eq('Old name')
        expect(bookmark.public).to be(true)
      end
    end

    it "succeeds with both parameters", :show_in_doc do
      user = api_login
      bookmark = create(:bookmark, user: user, name: "Old name")

      aggregate_failures do
        expect(bookmark.name).to eq("Old name")
        expect(bookmark.public).to be(false)
      end

      patch :update, params: { id: bookmark.id, name: "New name", public: true }
      bookmark.reload

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.parsed_body['name']).to eq("New name")
        expect(response.parsed_body['public']).to be(true)
        expect(bookmark.name).to eq('New name')
        expect(bookmark.public).to be(true)
      end
    end
  end

  describe "DELETE destroy" do
    it "requires login", :show_in_doc do
      delete :destroy, params: { id: 0 }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires valid bookmark", :show_in_doc do
      api_login
      delete :destroy, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Bookmark could not be found.")
    end

    it "requires visible bookmark", :show_in_doc do
      api_login
      bookmark = create(:bookmark)
      bookmark.post.update!(privacy: :private)
      delete :destroy, params: { id: bookmark.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "requires ownership of bookmark", :show_in_doc do
      api_login
      bookmark = create(:bookmark, user: create(:user, public_bookmarks: true))
      delete :destroy, params: { id: bookmark.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "handles failed destroys" do
      user = api_login
      bookmark = create(:bookmark, user: user)

      allow(Bookmark).to receive(:find_by).and_call_original
      allow(Bookmark).to receive(:find_by).with({ id: bookmark.id.to_s }).and_return(bookmark)
      allow(bookmark).to receive(:destroy).and_return(false)
      expect(bookmark).to receive(:destroy)

      delete :destroy, params: { id: bookmark.id }

      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq('Bookmark could not be removed.')
    end

    it "succeeds with valid bookmark", :show_in_doc do
      user = api_login
      bookmark = create(:bookmark, user: user)

      delete :destroy, params: { id: bookmark.id }

      expect(response).to have_http_status(204)
      expect(response.parsed_body).to eq("")
      expect(Bookmark.find_by_id(bookmark.id)).to be_nil
    end
  end
end
