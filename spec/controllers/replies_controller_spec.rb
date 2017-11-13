require "spec_helper"

RSpec.describe RepliesController do
  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "preview" do
      it "takes correct actions" do
        user = create(:user)
        reply_post = create(:post, user: user)
        reply = create(:reply, post: reply_post)
        reply_post.mark_read(user)
        login_as(user)
        expect(ReplyDraft.count).to eq(0)

        char1 = create(:character, user: user)
        char2 = create(:template_character, user: user)
        expect(controller).to receive(:build_template_groups).and_call_original
        expect(controller).to receive(:make_draft).and_call_original
        expect(controller).to receive(:setup_layout_gon).and_call_original

        post :create, params: { button_preview: true, reply: {post_id: reply_post.id} }
        expect(response).to render_template(:preview)
        expect(assigns(:javascripts)).to include('posts/editor')
        expect(assigns(:page_title)).to eq(reply_post.subject)
        expect(assigns(:written)).to be_a_new_record
        expect(assigns(:written).user).to eq(reply_post.user)
        expect(assigns(:post)).to eq(reply_post)
        expect(ReplyDraft.count).to eq(1)
        draft = ReplyDraft.last
        expect(draft.post).to eq(reply_post)
        expect(draft.user).to eq(reply_post.user)
        expect(flash[:success]).to eq('Draft saved!')

        # build_template_groups:
        expect(controller.gon.current_user).not_to be_nil
        # templates
        templates = assigns(:templates)
        expect(templates.length).to eq(2)
        template_chars = templates.first
        expect(template_chars).to eq(char2.template)
        templateless = templates.last
        expect(templateless.name).to eq('Templateless')
        expect(templateless.plucked_characters).to eq([[char1.id, char1.name]])
      end
    end

    context "draft" do
      it "displays errors if relevant" do
        draft = create(:reply_draft)
        login_as(draft.user)
        post :create, params: { button_draft: true, reply: {post_id: ''} }
        expect(flash[:error][:message]).to eq("Your draft could not be saved because of the following problems:")
        expect(draft.reload.post_id).not_to be_nil
        expect(response).to redirect_to(posts_url)
      end

      it "creates a new draft if none exists" do
        user = create(:user)
        reply_post = create(:post, user: user)
        login_as(user)
        char = create(:character, user: user)
        icon = create(:icon, user: user)
        calias = create(:alias, character: char)

        expect(ReplyDraft.count).to eq(0)
        post :create, params: { button_draft: true, reply: {post_id: reply_post.id, character_id: char.id, icon_id: icon.id, content: 'testcontent', character_alias_id: calias.id} }
        expect(response).to redirect_to(post_url(reply_post, page: :unread, anchor: :unread))
        expect(flash[:success]).to eq("Draft saved!")
        expect(ReplyDraft.count).to eq(1)

        draft = ReplyDraft.last
        expect(draft.post).to eq(reply_post)
        expect(draft.user).to eq(user)
        expect(draft.character_id).to eq(char.id)
        expect(draft.icon_id).to eq(icon.id)
        expect(draft.content).to eq('testcontent')
        expect(draft.character_alias_id).to eq(calias.id)
      end

      it "updates the existing draft if one exists" do
        draft = create(:reply_draft)
        login_as(draft.user)
        post :create, params: { button_draft: true, reply: {post_id: draft.post.id, content: 'new draft'} }
        expect(flash[:success]).to eq("Draft saved!")
        expect(draft.reload.content).to eq('new draft')
        expect(ReplyDraft.count).to eq(1)
      end
    end

    it "requires valid post" do
      login
      post :create
      expect(response).to redirect_to(posts_url)
      expect(flash[:error][:message]).to eq("Your reply could not be saved because of the following problems:")
    end

    it "requires post read" do
      reply_post = create(:post)
      login_as(reply_post.user)
      reply_post.mark_read(reply_post.user)
      create(:reply, post: reply_post)

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id} }
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("There has been 1 new reply since you last viewed this post.")
    end

    it "handles multiple creations with unread warning" do
      reply_post = create(:post)
      login_as(reply_post.user)
      reply_post.mark_read(reply_post.user)
      last_seen = create(:reply, post: reply_post)

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id} }
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("There has been 1 new reply since you last viewed this post.")

      create(:reply, post: reply_post)
      create(:reply, post: reply_post)

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id} }
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("There have been 2 new replies since you last viewed this post.")
    end

    it "handles multiple creations by user" do
      reply_post = create(:post)
      login_as(reply_post.user)
      dupe_reply = create(:reply, user: reply_post.user, post: reply_post)
      reply_post.mark_read(reply_post.user, dupe_reply.created_at + 1.second, true)

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id, content: dupe_reply.content} }
      expect(response).to have_http_status(200)
      expect(flash[:error]).to eq("This looks like a duplicate. Did you attempt to post this twice? Please resubmit if this was intentional.")

      post :create, params: { reply: {post_id: reply_post.id, user_id: reply_post.user_id, content: dupe_reply.content}, allow_dupe: true }
      expect(response).to have_http_status(302)
      expect(flash[:success]).to eq("Posted!")
    end

    it "requires valid params if read" do
      user = create(:user)
      login_as(user)
      character = create(:character)
      reply_post = create(:post)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)

      expect(character.user_id).not_to eq(user.id)
      post :create, params: { reply: {character_id: character.id, post_id: reply_post.id} }
      expect(response).to redirect_to(post_url(reply_post))
      expect(flash[:error][:message]).to eq("Your reply could not be saved because of the following problems:")
    end

    it "saves a new reply successfully if read" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)
      expect(Reply.count).to eq(0)
      char = create(:character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test!', character_id: char.id, icon_id: icon.id, character_alias_id: calias.id} }

      reply = Reply.first
      expect(reply).not_to be_nil
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq("Posted!")
      expect(reply.user).to eq(user)
      expect(reply.post).to eq(reply_post)
      expect(reply.content).to eq('test!')
      expect(reply.character_id).to eq(char.id)
      expect(reply.icon_id).to eq(icon.id)
      expect(reply.character_alias_id).to eq(calias.id)
    end

    it "allows you to reply to a post you created" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post, user: user)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)
      expect(Reply.count).to eq(0)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test content!'} }
      reply = Reply.first
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(reply).not_to be_nil
      expect(flash[:success]).to eq('Posted!')
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content!')
    end

    it "allows you to reply to join a post you did not create" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_post.mark_read(user, reply_post.created_at + 1.second, true)
      expect(Reply.count).to eq(0)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test content again!'} }
      reply = Reply.first
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(reply).not_to be_nil
      expect(flash[:success]).to eq('Posted!')
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content again!')
    end

    it "allows you to reply to a post you already joined" do
      user = create(:user)
      login_as(user)
      reply_post = create(:post)
      reply_old = create(:reply, post: reply_post, user: user)
      reply_post.mark_read(user, reply_old.created_at + 1.second, true)
      expect(Reply.count).to eq(1)

      post :create, params: { reply: {post_id: reply_post.id, content: 'test content the third!'} }
      expect(Reply.count).to eq(2)
      reply = Reply.order(id: :desc).first
      expect(reply).not_to eq(reply_old)
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq('Posted!')
      expect(reply.user).to eq(user)
      expect(reply.content).to eq('test content the third!')
    end
  end

  describe "GET show" do
    it "requires valid reply" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to eq(true)

      reply.post.privacy = Concealable::PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      get :show, params: { id: reply.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "succeeds when logged out" do
      reply = create(:reply)
      get :show, params: { id: reply.id }
      expect(response).to have_http_status(200)
      expect(assigns(:javascripts)).to include('posts/show')
    end

    it "succeeds when logged in" do
      reply = create(:reply)
      login
      get :show, params: { id: reply.id }
      expect(response).to have_http_status(200)
      expect(assigns(:javascripts)).to include('posts/show')
    end

    it "has more tests" do
      skip
    end
  end

  describe "GET history" do
    it "requires valid reply" do
      get :history, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to eq(true)

      reply.post.privacy = Concealable::PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      get :history, params: { id: reply.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "works when logged out" do
      reply = create(:reply)
      get :history, params: { id: reply.id }
      expect(response.status).to eq(200)
    end

    it "works when logged in" do
      reply = create(:reply)
      login
      get :history, params: { id: reply.id }
      expect(response.status).to eq(200)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid reply" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to eq(true)

      reply.post.privacy = Concealable::PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      get :edit, params: { id: reply.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "requires reply access" do
      reply = create(:reply)
      login
      get :edit, params: { id: reply.id }
      expect(response).to redirect_to(post_url(reply.post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "works" do
      user = create(:user)
      reply = create(:reply, user: user)
      login_as(user)
      char1 = create(:character, user: user)
      char2 = create(:template_character, user: user)
      expect(controller).to receive(:build_template_groups).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      get :edit, params: { id: reply.id }
      expect(response).to render_template(:edit)
      expect(assigns(:page_title)).to eq(reply.post.subject)
      expect(assigns(:reply)).to eq(reply)
      expect(assigns(:post)).to eq(reply.post)

      # build_template_groups:
      expect(controller.gon.current_user).not_to be_nil
      # templates
      templates = assigns(:templates)
      expect(templates.length).to eq(2)
      template_chars = templates.first
      expect(template_chars).to eq(char2.template)
      templateless = templates.last
      expect(templateless.name).to eq('Templateless')
      expect(templateless.plucked_characters).to eq([[char1.id, char1.name]])
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid reply" do
      login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to eq(true)

      reply.post.privacy = Concealable::PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      put :update, params: { id: reply.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "requires reply access" do
      reply = create(:reply)
      login
      put :update, params: { id: reply.id }
      expect(response).to redirect_to(post_url(reply.post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires notes from moderators" do
      reply = create(:reply)
      login_as(create(:admin_user))
      put :update, params: { id: reply.id }
      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq('You must provide a reason for your moderator edit.')
    end

    it "fails when invalid" do
      reply = create(:reply)
      login_as(reply.user)
      put :update, params: { id: reply.id, reply: { post_id: nil } }
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Your reply could not be saved because of the following problems:")
    end

    it "succeeds" do
      user = create(:user)
      reply = create(:reply, user: user)
      newcontent = reply.content + 'new'
      login_as(user)
      char = create(:character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char)

      put :update, params: { id: reply.id, reply: {content: newcontent, character_id: char.id, icon_id: icon.id, character_alias_id: calias.id} }
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq("Post updated")

      reply.reload
      expect(reply.content).to eq(newcontent)
      expect(reply.character_id).to eq(char.id)
      expect(reply.icon_id).to eq(icon.id)
      expect(reply.character_alias_id).to eq(calias.id)
    end

    context "preview" do
      skip
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid reply" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to eq(true)

      reply.post.privacy = Concealable::PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      delete :destroy, params: { id: reply.id }
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "requires reply access" do
      reply = create(:reply)
      login
      delete :destroy, params: { id: reply.id }
      expect(response).to redirect_to(post_url(reply.post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "succeeds for reply creator" do
      reply = create(:reply)
      login_as(reply.user)
      delete :destroy, params: { id: reply.id }
      expect(response).to redirect_to(post_url(reply.post, page: 1))
      expect(flash[:success]).to eq("Post deleted.")
      expect(Reply.find_by_id(reply.id)).to be_nil
    end

    it "succeeds for admin user" do
      reply = create(:reply)
      login_as(create(:admin_user))
      delete :destroy, params: { id: reply.id }
      expect(response).to redirect_to(post_url(reply.post, page: 1))
      expect(flash[:success]).to eq("Post deleted.")
      expect(Reply.find_by_id(reply.id)).to be_nil
    end

    it "respects per_page when redirecting" do
      reply = create(:reply) # p1
      reply = create(:reply, post: reply.post, user: reply.user) # p1
      reply = create(:reply, post: reply.post, user: reply.user) # p2
      reply = create(:reply, post: reply.post, user: reply.user) # p2
      login_as(reply.user)
      delete :destroy, params: { id: reply.id, per_page: 2 }
      expect(response).to redirect_to(post_url(reply.post, page: 2))
    end

    it "respects per_page when redirecting first on page" do
      reply = create(:reply) # p1
      reply = create(:reply, post: reply.post, user: reply.user) # p1
      reply = create(:reply, post: reply.post, user: reply.user) # p2
      reply = create(:reply, post: reply.post, user: reply.user) # p2
      reply = create(:reply, post: reply.post, user: reply.user) # p3
      login_as(reply.user)
      delete :destroy, params: { id: reply.id, per_page: 2 }
      expect(response).to redirect_to(post_url(reply.post, page: 2))
    end
  end

  describe "GET search" do
    context "no search" do
      before(:each) do
        2.times do
          create(:user)
          create(:character)
          create(:template_character)
        end
      end

      it "works logged out" do
        get :search
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Replies')
        expect(assigns(:post)).to be_nil
        expect(assigns(:search_results)).to be_nil
        expect(assigns(:users)).to be_nil # this will be dynamically loaded
        expect(assigns(:characters)).to be_nil # this will be dynamically loaded
        expect(assigns(:users)).to be_nil # this will be dynamically loaded
        expect(assigns(:templates).size).to eq(2) # this will be dynamically loaded
      end

      it "works logged in" do
        login
        get :search
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Replies')
        expect(assigns(:post)).to be_nil
        expect(assigns(:search_results)).to be_nil
      end

      it "sets templates by author" do
        author = create(:user)
        template = create(:template, user: author)
        create(:template)
        get :search, params: { commit: true, author_id: author.id }
        expect(assigns(:templates)).to eq([template])
      end

      it "handles invalid post" do
        get :search, params: { post_id: -1 }
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Replies')
        expect(assigns(:post)).to be_nil
        expect(assigns(:search_results)).to be_nil
      end

      it "handles valid post" do
        templateless_char = Character.where(template_id: nil).first
        post = create(:post, character: templateless_char, user: templateless_char.user)
        get :search, params: { post_id: post.id }
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Replies')
        expect(assigns(:post)).to eq(post)
        expect(assigns(:search_results)).to be_nil
        expect(assigns(:users)).to match_array(post.authors)
        expect(assigns(:characters)).to match_array([post.character])
        expect(assigns(:templates)).to be_empty
      end
    end

    context "searching" do
      it "finds all when no arguments given" do
        4.times do create(:reply) end
        get :search, params: { commit: true }
        expect(assigns(:search_results)).to match_array(Reply.all)
      end

      it "filters by author" do
        replies = Array.new(4) { create(:reply) }
        filtered_reply = replies.last
        get :search, params: { commit: true, author_id: filtered_reply.user_id }
        expect(assigns(:search_results)).to match_array([filtered_reply])
      end

      it "filters by icon" do
        create(:reply, with_icon: true)
        reply = create(:reply, with_icon: true)
        get :search, params: { commit: true, icon_id: reply.icon_id }
        expect(assigns(:search_results)).to match_array([reply])
      end

      it "filters by character" do
        create(:reply, with_character: true)
        reply = create(:reply, with_character: true)
        get :search, params: { commit: true, character_id: reply.character_id }
        expect(assigns(:search_results)).to match_array([reply])
      end

      it "filters by string" do
        reply = create(:reply, content: 'contains seagull')
        cap_reply = create(:reply, content: 'Seagull is capital')
        create(:reply, content: 'nope')
        get :search, params: { commit: true, subj_content: 'seagull' }
        expect(assigns(:search_results)).to match_array([reply, cap_reply])
      end

      it "filters by exact match" do
        create(:reply, content: 'contains forks')
        create(:reply, content: 'Forks is capital')
        reply = create(:reply, content: 'Forks High is capital')
        create(:reply, content: 'Forks high is kinda capital')
        create(:reply, content: 'forks High is different capital')
        create(:reply, content: 'forks high is not capital')
        create(:reply, content: 'Forks is split from High')
        create(:reply, content: 'nope')
        get :search, params: { commit: true, subj_content: '"Forks High"' }
        expect(assigns(:search_results)).to match_array([reply])
      end

      it "only shows from visible posts" do
        reply1 = create(:reply, content: 'contains forks')
        reply2 = create(:reply, content: 'visible contains forks')
        reply1.post.update_attributes(privacy: Concealable::PRIVATE)
        expect(reply1.post.reload).not_to be_visible_to(nil) # logged out, not visible
        expect(reply2.post.reload).to be_visible_to(nil)
        get :search, params: { commit: true, subj_content: 'forks' }
        expect(assigns(:search_results)).to match_array([reply2])
      end

      it "filters by post" do
        replies = Array.new(4) { create(:reply) }
        filtered_reply = replies.last
        get :search, params: { commit: true, post_id: filtered_reply.post_id }
        expect(assigns(:search_results)).to match_array([filtered_reply])
      end

      it "requires visible post if given" do
        reply1 = create(:reply)
        reply1.post.update_attributes(privacy: Concealable::PRIVATE)
        expect(reply1.post.reload).not_to be_visible_to(nil)
        get :search, params: { commit: true, post_id: reply1.post_id }
        expect(assigns(:search_results)).to be_nil
        expect(flash[:error]).to eq('You do not have permission to view this post.')
      end

      it "filters by continuity" do
        continuity_post = create(:post, num_replies: 1)
        create(:post, num_replies: 1) # wrong post
        filtered_reply = continuity_post.replies.last
        get :search, params: { commit: true, board_id: continuity_post.board_id }
        expect(assigns(:search_results)).to match_array([filtered_reply])
      end

      it "filters by template" do
        character = create(:template_character)
        templateless_char = create(:character)
        reply = create(:reply, character: character, user: character.user)
        create(:reply, character: templateless_char, user: templateless_char.user)
        get :search, params: { commit: true, template_id: character.template_id }
        expect(assigns(:search_results)).to match_array([reply])
      end
    end
  end
end
