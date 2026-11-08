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
  end

  describe "POST create" do
    let(:user) { create(:user) }
    let(:reply_post) { create(:post) }

    it "requires login", :show_in_doc do
      post :create, params: { post_id: reply_post.id, content: 'test' }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires valid post", :show_in_doc do
      api_login
      post :create, params: { post_id: 0, content: 'test' }
      expect(response).to have_http_status(404)
      expect(response.parsed_body['errors'][0]['message']).to eq("Post could not be found.")
    end

    context "with permission failures" do
      def expect_denied(params={})
        expect {
          post :create, params: { post_id: reply_post.id, content: 'test' }.merge(params)
        }.not_to change { Reply.count }
        expect(response).to have_http_status(403)
        expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
      end

      it "requires access to post", :show_in_doc do
        api_login_as(user)
        reply_post.update!(privacy: :private)
        expect_denied
      end

      it "requires a full account" do
        api_login_as(create(:reader_user))
        expect_denied
      end

      it "rejects suspended users" do
        api_login_as(create(:user, role_id: Permissible::SUSPENDED))
        expect_denied
      end

      it "rejects deleted users" do
        api_login_as(create(:user, deleted: true))
        expect_denied
      end

      it "rejects complete posts" do
        api_login_as(user)
        reply_post.update!(status: :complete)
        expect_denied
      end

      it "rejects abandoned posts" do
        api_login_as(user)
        reply_post.update!(status: :abandoned)
        expect_denied
      end

      it "rejects closed posts for non-authors" do
        api_login_as(user)
        reply_post.update!(authors_locked: true)
        expect_denied
      end

      it "rejects closed continuities for non-writers" do
        api_login_as(user)
        writer = create(:user)
        board = create(:board, writers: [writer])
        board_post = create(:post, board: board, user: writer)
        expect {
          post :create, params: { post_id: board_post.id, content: 'test' }
        }.not_to change { Reply.count }
        expect(response).to have_http_status(403)
      end

      it "rejects posts by authors who block the user" do
        api_login_as(user)
        reply_post.update!(authors_locked: true)
        create(:block, blocking_user: reply_post.user, blocked_user: user, hide_me: :posts)
        expect_denied
      end

      it "rejects authors who may no longer reply" do
        api_login_as(user)
        locked_post = create(:post, authors_locked: true, unjoined_authors: [user])
        locked_post.author_for(user).update!(can_reply: false)
        expect {
          post :create, params: { post_id: locked_post.id, content: 'test' }
        }.not_to change { Reply.count }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq("User #{user.username} cannot write in this post")
      end
    end

    context "with invalid parameters" do
      before(:each) do
        api_login_as(user)
        reply_post.mark_read(user)
      end

      def expect_invalid(params, message)
        expect {
          post :create, params: { post_id: reply_post.id, content: 'test' }.merge(params)
        }.not_to change { Reply.count }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'].pluck('message')).to include(message)
      end

      it "rejects another user's character", :show_in_doc do
        expect_invalid({ character_id: create(:character).id }, "Character must be yours")
      end

      it "rejects another user's icon" do
        expect_invalid({ icon_id: create(:icon).id }, "Icon must be yours")
      end

      it "rejects a missing character" do
        expect_invalid({ character_id: 0 }, "Character could not be found.")
      end

      it "rejects a missing icon" do
        expect_invalid({ icon_id: 0 }, "Icon could not be found.")
      end

      it "rejects a missing alias" do
        character = create(:character, user: user)
        expect_invalid({ character_id: character.id, character_alias_id: 0 }, "Character alias could not be found.")
      end

      it "rejects an alias of a different character" do
        character = create(:character, user: user)
        calias = create(:alias)
        expect_invalid({ character_id: character.id, character_alias_id: calias.id }, "Character alias must belong to the reply's character.")
      end

      it "rejects an alias without a character" do
        calias = create(:alias, character: create(:character, user: user))
        expect_invalid({ character_alias_id: calias.id }, "Character alias must belong to the reply's character.")
      end

      it "rejects an invalid editor mode" do
        expect {
          post :create, params: { post_id: reply_post.id, content: 'test', editor_mode: 'fake' }
        }.not_to change { Reply.count }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to include('editor_mode')
      end

      it "rejects a last seen reply from another post" do
        expect_invalid({ last_seen_reply_id: create(:reply).id }, "Reply could not be found.")
      end
    end

    context "with unseen replies" do
      it "warns about replies posted since the user last read the post", :show_in_doc do
        api_login_as(user)
        reply_post.mark_read(user)
        other_reply = create(:reply, post: reply_post)

        expect {
          post :create, params: { post_id: reply_post.id, content: 'test' }
        }.not_to change { Reply.count }
        expect(response).to have_http_status(409)
        expect(response.parsed_body['errors'][0]['message']).to eq("There has been 1 new reply since you last viewed this post.")
        expect(response.parsed_body['unseen_replies'].pluck('id')).to eq([other_reply.id])

        # the warning marks the shown replies as read, so a retry succeeds
        api_login_as(user)
        expect {
          post :create, params: { post_id: reply_post.id, content: 'test' }
        }.to change { Reply.count }.by(1)
        expect(response).to have_http_status(200)
      end

      it "warns about replies in a post the user has not read" do
        api_login_as(user)
        unread_post = create(:post, num_replies: 2)

        expect {
          post :create, params: { post_id: unread_post.id, content: 'test' }
        }.not_to change { Reply.count }
        expect(response).to have_http_status(409)
        expect(response.parsed_body['errors'][0]['message']).to eq("There have been 2 new replies since you last viewed this post.")
        expect(response.parsed_body['unseen_replies'].pluck('id')).to eq(unread_post.replies.ordered.pluck(:id))
      end

      it "uses the given last seen reply" do
        api_login_as(user)
        first_reply = create(:reply, post: reply_post)
        second_reply = create(:reply, post: reply_post)

        post :create, params: { post_id: reply_post.id, content: 'test', last_seen_reply_id: first_reply.id }
        expect(response).to have_http_status(409)
        expect(response.parsed_body['unseen_replies'].pluck('id')).to eq([second_reply.id])

        api_login_as(user)
        expect {
          post :create, params: { post_id: reply_post.id, content: 'test', last_seen_reply_id: second_reply.id }
        }.to change { Reply.count }.by(1)
        expect(response).to have_http_status(200)
      end
    end

    context "with duplicates" do
      let!(:previous_reply) { create(:reply, post: reply_post, user: user) }

      before(:each) do
        api_login_as(user)
        reply_post.mark_read(user)
      end

      it "warns about a duplicate reply", :show_in_doc do
        expect {
          post :create, params: { post_id: reply_post.id, content: previous_reply.content }
        }.not_to change { Reply.count }
        expect(response).to have_http_status(409)
        expect(response.parsed_body['errors'][0]['message']).to start_with("This looks like a duplicate.")
      end

      it "allows a duplicate reply with allow_dupe" do
        expect {
          post :create, params: { post_id: reply_post.id, content: previous_reply.content, allow_dupe: true }
        }.to change { Reply.count }.by(1)
        expect(response).to have_http_status(200)
      end
    end

    context "with valid parameters" do
      before(:each) do
        api_login_as(user)
        reply_post.mark_read(user)
      end

      it "creates a reply", :show_in_doc do
        character = create(:character, user: user)
        icon = create(:icon, user: user)
        calias = create(:alias, character: character)

        expect {
          post :create, params: {
            post_id: reply_post.id,
            content: 'test content',
            character_id: character.id,
            icon_id: icon.id,
            character_alias_id: calias.id,
            editor_mode: 'md',
          }
        }.to change { Reply.count }.by(1)

        reply = Reply.order(:id).last
        aggregate_failures do
          expect(response).to have_http_status(200)
          expect(reply.post).to eq(reply_post)
          expect(reply.user).to eq(user)
          expect(reply.content).to eq('test content')
          expect(reply.character).to eq(character)
          expect(reply.icon).to eq(icon)
          expect(reply.character_alias).to eq(calias)
          expect(reply.editor_mode).to eq('md')

          json = response.parsed_body
          expect(json['id']).to eq(reply.id)
          expect(json['content']).to eq('test content')
          expect(json['character_name']).to eq(calias.name)
          expect(json['character']['id']).to eq(character.id)
          expect(json['character']['name']).to eq(character.name)
          expect(json['icon']['id']).to eq(icon.id)
          expect(json['user']['id']).to eq(user.id)
        end
      end

      it "creates a reply without a character or icon" do
        post :create, params: { post_id: reply_post.id, content: 'test' }
        expect(response).to have_http_status(200)
        reply = Reply.find(response.parsed_body['id'])
        expect(reply.character).to be_nil
        expect(reply.icon).to be_nil
        expect(response.parsed_body['character']).to be_nil
        expect(response.parsed_body['icon']).to be_nil
      end

      it "defaults to the user's editor mode" do
        user.update!(default_editor: 'html')
        post :create, params: { post_id: reply_post.id, content: 'test' }
        expect(response).to have_http_status(200)
        expect(Reply.find(response.parsed_body['id']).editor_mode).to eq('html')
      end

      it "sanitizes the rendered content" do
        post :create, params: { post_id: reply_post.id, content: '<script>alert(1)</script>hello', editor_mode: 'html' }
        expect(response).to have_http_status(200)
        reply = Reply.find(response.parsed_body['id'])
        expect(reply.rendered_content).not_to include('<script')
        expect(reply.rendered_content).to include('hello')
      end

      it "updates the post, the authors and the user's read position" do
        character = create(:character, user: user)
        post :create, params: { post_id: reply_post.id, content: 'test', character_id: character.id }
        expect(response).to have_http_status(200)

        reply = Reply.find(response.parsed_body['id'])
        updated_post = Post.find(reply_post.id)
        aggregate_failures do
          expect(updated_post.last_reply).to eq(reply)
          expect(updated_post.last_user).to eq(user)
          expect(updated_post.tagged_at).to be_the_same_time_as(reply.updated_at)
          expect(updated_post.author_for(user).joined).to be(true)
          expect(updated_post.first_unread_for(user)).to be_nil
          expect(user.reload.active_character).to eq(character)
        end
      end

      it "lets an invited author reply to a closed post" do
        locked_post = create(:post, authors_locked: true, unjoined_authors: [user])
        locked_post.mark_read(user)
        expect {
          post :create, params: { post_id: locked_post.id, content: 'test' }
        }.to change { Reply.count }.by(1)
        expect(response).to have_http_status(200)
        expect(locked_post.author_for(user).reload.joined).to be(true)
      end

      it "notifies other authors" do
        reply_post.user.update!(email_notifications: true)
        expect {
          post :create, params: { post_id: reply_post.id, content: 'test' }
        }.to have_enqueued_email(UserMailer, :post_has_new_reply)
        expect(response).to have_http_status(200)
      end

      it "regenerates the flat post" do
        expect(GenerateFlatPostJob).to receive(:enqueue).with(reply_post.id).at_least(:once)
        post :create, params: { post_id: reply_post.id, content: 'test' }
        expect(response).to have_http_status(200)
      end

      it "removes the user's draft" do
        create(:reply_draft, post: reply_post, user: user)
        expect {
          post :create, params: { post_id: reply_post.id, content: 'test' }
        }.to change { ReplyDraft.count }.by(-1)
        expect(response).to have_http_status(200)
      end
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
