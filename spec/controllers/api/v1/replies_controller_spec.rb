RSpec.describe Api::V1::RepliesController do
  describe "GET index" do
    it "requires valid post", :show_in_doc do
      get :index, params: { post_id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires access to post", :show_in_doc do
      post = create(:post, privacy: :private)
      get :index, params: { post_id: post.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds with valid post", :show_in_doc do
      post = create(:post, num_replies: 2, with_icon: true, with_character: true)
      calias = create(:alias)
      reply = create(:reply, post: post, user: calias.character.user, character: calias.character, character_alias: calias, with_icon: true)
      expect(calias.name).not_to eq(reply.character.name)
      get :index, params: { post_id: post.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body.size).to eq(3)
      expect(response.parsed_body[2]['id']).to eq(reply.id)
      expect(response.parsed_body[2]['icon']['id']).to eq(reply.icon_id)
      expect(response.parsed_body[2]['character']['id']).to eq(reply.character_id)
      expect(response.parsed_body[2]['character']['name']).to eq(calias.character.name)
      expect(response.parsed_body[2]['character_name']).to eq(calias.name)
    end

    it "paginates" do
      post = create(:post, num_replies: 5, with_icon: true, with_character: true)
      get :index, params: { post_id: post.id, per_page: 2, page: 3 }
      expect(response).to have_http_status(200)
      expect(response.headers['Per-Page'].to_i).to eq(2)
      expect(response.headers['Page'].to_i).to eq(3)
      expect(response.headers['Total'].to_i).to eq(5)
      expect(response.headers['Link']).not_to be_nil
      expect(response.parsed_body.size).to eq(1)
    end

    it "includes editor mode for your own replies" do
      post = create(:post)
      reply = create(:reply, post: post, editor_mode: 'html')
      create(:reply, post: post, user: post.user)
      api_login_as(reply.user)
      get :index, params: { post_id: post.id }

      expect(response).to have_http_status(200)
      expect(response.parsed_body.size).to eq(2)
      expect(response.parsed_body[0]['user']['id']).to eq(reply.user_id)
      expect(response.parsed_body[0]['editor_mode']).to eq('html')
      expect(response.parsed_body[1]['user']['id']).to eq(post.user_id)
      expect(response.parsed_body[1]).not_to have_key('editor_mode')
    end
  end

  describe 'GET bookmark' do
    it 'requires user ID', :show_in_doc do
      get :bookmark, params: { id: 0 }
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq("Missing parameter user_id")
    end

    it 'requires a valid reply', :show_in_doc do
      get :bookmark, params: { id: 0, user_id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Reply could not be found.")
    end

    it 'requires a valid user', :show_in_doc do
      get :bookmark, params: { id: create(:reply).id, user_id: 0 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("User could not be found.")
    end

    it "fails with private post", :show_in_doc do
      reply = create(:reply)
      reply.post.update!(privacy: :private)
      get :bookmark, params: { id: reply.id, user_id: create(:user).id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "fails if bookmark does not exist", :show_in_doc do
      get :bookmark, params: { id: create(:reply).id, user_id: create(:user, public_bookmarks: true).id }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Bookmark could not be found.")
    end

    it "fails if bookmark is private", :show_in_doc do
      bookmark = create(:bookmark, user: create(:user))
      get :bookmark, params: { id: bookmark.reply.id, user_id: bookmark.user.id }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Bookmark could not be found.")
    end

    it "succeeds if bookmark is public", :show_in_doc do
      bookmark = create(:bookmark, user: create(:user), public: true)
      get :bookmark, params: { id: bookmark.reply.id, user_id: bookmark.user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(bookmark.id)
      expect(response.parsed_body['user_id']).to eq(bookmark.user.id)
      expect(response.parsed_body['reply_id']).to eq(bookmark.reply_id)
      expect(response.parsed_body['post_id']).to eq(bookmark.post_id)
    end

    it "Public bookmark doesn't override private post", :show_in_doc do
      bookmark = create(:bookmark, user: create(:user), public: true)
      bookmark.post.update!(privacy: :private)
      get :bookmark, params: { id: bookmark.reply.id, user_id: bookmark.user.id }
      expect(response).to have_http_status(403)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "succeeds if user bookmarks are public", :show_in_doc do
      bookmark = create(:bookmark, user: create(:user, public_bookmarks: true))
      get :bookmark, params: { id: bookmark.reply.id, user_id: bookmark.user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(bookmark.id)
      expect(response.parsed_body['user_id']).to eq(bookmark.user.id)
      expect(response.parsed_body['reply_id']).to eq(bookmark.reply_id)
      expect(response.parsed_body['post_id']).to eq(bookmark.post_id)
    end

    it "succeeds with own bookmarks", :show_in_doc do
      user = api_login
      bookmark = create(:bookmark, user: user)
      get :bookmark, params: { id: bookmark.reply.id, user_id: user.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(bookmark.id)
      expect(response.parsed_body['user_id']).to eq(user.id)
      expect(response.parsed_body['reply_id']).to eq(bookmark.reply_id)
      expect(response.parsed_body['post_id']).to eq(bookmark.post_id)
    end

    it "doesn't fetch a different user's bookmark", :show_in_doc do
      user1 = create(:user, public_bookmarks: true)
      user2 = create(:user, public_bookmarks: true)
      bookmark2 = create(:bookmark, user: user2)
      get :bookmark, params: { id: bookmark2.reply.id, user_id: user1.id }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'].size).to eq(1)
      expect(response.parsed_body['errors'][0]['message']).to eq("Bookmark could not be found.")
    end
  end
end
