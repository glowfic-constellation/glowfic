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

  describe "GET search" do
    def result_ids
      expect(response).to have_http_status(200), response.body
      response.parsed_body['results'].pluck('id')
    end

    it "returns replies in the reply API format with their post", :show_in_doc do
      post = create(:post, subject: 'Reply search post')
      calias = create(:alias)
      reply = create(:reply, post: post, user: calias.character.user, character: calias.character, character_alias: calias, with_icon: true)
      get :search
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(1)
      result = response.parsed_body['results'][0]
      expect(result['id']).to eq(reply.id)
      expect(result['content']).to eq(reply.content)
      expect(result['character_name']).to eq(calias.name)
      expect(result['character']).to eq({ 'id' => reply.character_id, 'name' => calias.character.name, 'screenname' => reply.character.screenname })
      expect(result['icon']).to eq({ 'id' => reply.icon_id, 'url' => reply.icon.url, 'keyword' => reply.icon.keyword })
      expect(result['user']).to eq({ 'id' => reply.user_id, 'username' => reply.user.username })
      expect(result['post']).to eq({ 'id' => post.id, 'subject' => 'Reply search post' })
      expect(result).not_to have_key('highlight')
    end

    it "returns icons even when condensed is given" do
      reply = create(:reply, with_icon: true)
      get :search, params: { condensed: 'on' }
      expect(response.parsed_body['results'][0]['icon']['id']).to eq(reply.icon_id)
    end

    it "sorts newest first by default" do
      reply = create(:reply)
      reply2 = Timecop.freeze(reply.created_at + 2.minutes) { create(:reply) }
      get :search
      expect(result_ids).to eq([reply2.id, reply.id])
    end

    it "sorts newest first with created_new and no filters", :show_in_doc do
      reply = create(:reply)
      reply2 = Timecop.freeze(reply.created_at + 2.minutes) { create(:reply) }
      reply3 = Timecop.freeze(reply.created_at + 4.minutes) { create(:reply) }
      get :search, params: { sort: 'created_new' }
      expect(response).to have_http_status(200)
      expect(result_ids).to eq([reply3.id, reply2.id, reply.id])
    end

    it "sorts oldest first with created_old" do
      reply = create(:reply)
      reply2 = Timecop.freeze(reply.created_at + 2.minutes) { create(:reply) }
      get :search, params: { sort: 'created_old' }
      expect(result_ids).to eq([reply.id, reply2.id])
    end

    it "searches content", :show_in_doc do
      reply = create(:reply, content: 'contains seagull')
      cap_reply = create(:reply, content: 'Seagull is capital')
      create(:reply, content: 'nope')
      get :search, params: { subj_content: 'seagull' }
      expect(response).to have_http_status(200)
      expect(result_ids).to match_array([reply.id, cap_reply.id])
      result = response.parsed_body['results'].detect { |r| r['id'] == reply.id }
      expect(result['content']).to eq('contains seagull')
      expect(result['highlight']).to include('<b>seagull</b>')
    end

    it "requires quoted phrases to match exactly, case-insensitively" do
      create(:reply, content: 'contains forks')
      create(:reply, content: 'Forks is capital')
      reply1 = create(:reply, content: 'Forks High is capital')
      reply2 = create(:reply, content: 'Forks high is kinda capital')
      reply3 = create(:reply, content: 'forks High is different capital')
      create(:reply, content: 'Forks is split from High')
      get :search, params: { subj_content: '"Forks High"' }
      expect(result_ids).to match_array([reply1.id, reply2.id, reply3.id])
    end

    it "sorts content search results by date when asked" do
      reply = create(:reply, content: 'a seagull')
      reply2 = Timecop.freeze(reply.created_at + 2.minutes) { create(:reply, content: 'seagull seagull seagull') }
      get :search, params: { subj_content: 'seagull', sort: 'created_old' }
      expect(result_ids).to eq([reply.id, reply2.id])
      get :search, params: { subj_content: 'seagull', sort: 'created_new' }
      expect(result_ids).to eq([reply2.id, reply.id])
    end

    it "filters by author" do
      create(:reply)
      reply = create(:reply)
      get :search, params: { author_id: reply.user_id }
      expect(result_ids).to eq([reply.id])
    end

    it "filters by character" do
      create(:reply, with_character: true)
      reply = create(:reply, with_character: true)
      get :search, params: { character_id: reply.character_id }
      expect(result_ids).to eq([reply.id])
    end

    it "filters by template" do
      character = create(:template_character)
      reply = create(:reply, character: character, user: character.user)
      templateless = create(:character)
      create(:reply, character: templateless, user: templateless.user)
      get :search, params: { template_id: character.template_id }
      expect(result_ids).to eq([reply.id])
    end

    it "filters by template and author together" do
      character = create(:template_character)
      reply = create(:reply, character: character, user: character.user)
      create(:reply, user: character.user)
      get :search, params: { template_id: character.template_id, author_id: character.user_id }
      expect(result_ids).to eq([reply.id])
    end

    it "filters by icon" do
      create(:reply, with_icon: true)
      reply = create(:reply, with_icon: true)
      get :search, params: { icon_id: reply.icon_id }
      expect(result_ids).to eq([reply.id])
    end

    it "filters by continuity" do
      post = create(:post, num_replies: 1)
      create(:post, num_replies: 1)
      get :search, params: { board_id: post.board_id }
      expect(result_ids).to eq([post.replies.last.id])
    end

    it "excludes continuities" do
      included = create(:post, num_replies: 1)
      excluded = create(:post, num_replies: 1)
      get :search, params: { exclude_board_ids: [excluded.board_id] }
      expect(result_ids).to eq([included.replies.last.id])
    end

    it "filters by post" do
      post = create(:post, num_replies: 2)
      create(:reply)
      get :search, params: { post_id: post.id }
      expect(result_ids).to match_array(post.replies.pluck(:id))
    end

    it "combines filters" do
      character = create(:template_character)
      post = create(:post, user: character.user)
      reply = create(:reply, post: post, character: character, user: character.user, content: 'a seagull')
      create(:reply, post: post, character: character, user: character.user, content: 'a pigeon')
      create(:reply, character: character, user: character.user, content: 'another seagull')
      get :search, params: {
        subj_content: 'seagull',
        post_id: post.id,
        author_id: character.user_id,
        character_id: character.id,
        template_id: character.template_id,
        board_id: post.board_id,
        sort: 'created_new',
      }
      expect(result_ids).to eq([reply.id])
    end

    context "with invalid parameters" do
      it "requires a visible post", :show_in_doc do
        post = create(:post, privacy: :private, num_replies: 1)
        get :search, params: { post_id: post.id }
        expect(response).to have_http_status(403)
        expect(response.parsed_body['errors'][0]['message']).to eq("You do not have permission to perform this action.")
      end

      it "requires an existing post" do
        get :search, params: { post_id: 0 }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq("Post could not be found.")
      end

      {
        author_id: 'User',
        board_id: 'Board',
        character_id: 'Character',
        icon_id: 'Icon',
        template_id: 'Template',
      }.each do |param, klass|
        it "requires an existing record for #{param}" do
          create(:reply)
          get :search, params: { param => 0 }
          expect(response).to have_http_status(422)
          expect(response.parsed_body['errors'][0]['message']).to eq("#{klass} could not be found.")
        end
      end

      it "rejects a non-numeric id", :show_in_doc do
        get :search, params: { author_id: 'abc' }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to include('author_id')
      end

      it "rejects an unknown sort" do
        get :search, params: { sort: 'word_count' }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to include('sort')
      end
    end

    context "with privacy" do
      let(:author) { create(:user) }
      let!(:public_reply) { create(:reply, post: create(:post, user: author), user: author, content: 'public seagull') }
      let!(:private_reply) { create(:reply, post: create(:post, user: author, privacy: :private), user: author, content: 'private seagull') }
      let!(:registered_reply) { create(:reply, post: create(:post, user: author, privacy: :registered), user: author, content: 'registered seagull') }
      let!(:access_reply) { create(:reply, post: create(:post, user: author, privacy: :access_list), user: author, content: 'listed seagull') }

      it "only shows replies in public posts when logged out" do
        get :search, params: { subj_content: 'seagull' }
        expect(result_ids).to eq([public_reply.id])
        expect(response.headers['Total'].to_i).to eq(1)
      end

      it "only shows replies in public posts when logged out with no filters" do
        get :search, params: { sort: 'created_new' }
        expect(result_ids).to eq([public_reply.id])
        expect(response.headers['Total'].to_i).to eq(1)
      end

      it "hides private and inaccessible posts from other users" do
        api_login
        get :search, params: { subj_content: 'seagull' }
        expect(result_ids).to match_array([public_reply.id, registered_reply.id])
        expect(response.headers['Total'].to_i).to eq(2)
      end

      it "shows access-listed posts to viewers" do
        viewer = api_login
        PostViewer.create!(post: access_reply.post, user: viewer)
        get :search, params: { subj_content: 'seagull' }
        expect(result_ids).to match_array([public_reply.id, registered_reply.id, access_reply.id])
      end

      it "shows all posts to the author" do
        api_login_as(author)
        get :search, params: { author_id: author.id }
        expect(result_ids).to match_array([public_reply.id, private_reply.id, registered_reply.id, access_reply.id])
        expect(response.headers['Total'].to_i).to eq(4)
      end

      it "hides posts from authors who block the user" do
        user = create(:user)
        public_reply.post.update!(authors_locked: true)
        create(:block, blocking_user: author, blocked_user: user, hide_me: :posts)
        api_login_as(user)
        get :search, params: { subj_content: 'seagull' }
        expect(result_ids).to eq([registered_reply.id])
      end

      it "hides posts the user has hidden with a block" do
        user = create(:user)
        public_reply.post.update!(authors_locked: true)
        create(:block, blocking_user: user, blocked_user: author, hide_them: :posts)
        api_login_as(user)
        get :search, params: { subj_content: 'seagull' }
        expect(result_ids).to eq([registered_reply.id])
      end

      it "does not let show_blocked reveal hidden posts" do
        user = create(:user)
        public_reply.post.update!(authors_locked: true)
        create(:block, blocking_user: user, blocked_user: author, hide_them: :posts)
        api_login_as(user)
        get :search, params: { subj_content: 'seagull', show_blocked: true }
        expect(result_ids).to eq([registered_reply.id])
      end
    end

    it "paginates 25 per page" do
      create(:post, num_replies: 26)
      get :search, params: { page: 2, sort: 'created_old' }
      expect(response).to have_http_status(200)
      expect(response.headers['Per-Page'].to_i).to eq(25)
      expect(response.headers['Page'].to_i).to eq(2)
      expect(response.headers['Total'].to_i).to eq(26)
      expect(response.headers['Link']).not_to be_nil
      expect(result_ids.size).to eq(1)
    end

    it "ignores per_page" do
      create(:post, num_replies: 26)
      get :search, params: { per_page: 100 }
      expect(response.headers['Per-Page'].to_i).to eq(25)
      expect(result_ids.size).to eq(25)
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
