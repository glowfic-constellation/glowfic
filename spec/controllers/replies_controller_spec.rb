require "spec_helper"

RSpec.describe RepliesController do
  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    context "preview" do
      skip
    end

    context "draft" do
      skip
    end

    it "requires valid post" do
      login
      post :create
      expect(response).to redirect_to(posts_url)
      expect(flash[:error][:message]).to eq("Your post could not be saved because of the following problems:")
    end

    it "requires valid params" do
      user_id = login
      character = create(:character)
      reply_post = create(:post)
      expect(character.user_id).not_to eq(user_id)
      post :create, reply: {character_id: character.id, post_id: reply_post.id}
      expect(response).to redirect_to(post_url(reply_post))
      expect(flash[:error][:message]).to eq("Your post could not be saved because of the following problems:")
    end

    it "saves a new reply" do
      login
      reply_post = create(:post)
      expect(Reply.count).to eq(0)

      post :create, reply: {post_id: reply_post.id}, content: 'test!'

      reply = Reply.first
      expect(reply).not_to be_nil
      expect(response).to redirect_to(reply_url(reply, anchor: "reply-#{reply.id}"))
      expect(flash[:success]).to eq("Posted!")
    end
  end

  describe "GET show" do
    it "requires valid reply" do
      get :show, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to be_true

      reply.post.privacy = Post::PRIVACY_PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      get :show, id: reply.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "GET history" do
    it "requires valid reply" do
      get :history, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to be_true

      reply.post.privacy = Post::PRIVACY_PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      get :history, id: reply.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "works when logged out" do
      reply = create(:reply)
      get :history, id: reply.id
      expect(response.status).to eq(200)
    end

    it "works when logged in" do
      reply = create(:reply)
      login
      get :history, id: reply.id
      expect(response.status).to eq(200)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid reply" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to be_true

      reply.post.privacy = Post::PRIVACY_PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      get :edit, id: reply.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid reply" do
      login
      put :update, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to be_true

      reply.post.privacy = Post::PRIVACY_PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      put :update, id: reply.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid reply" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("Post could not be found.")
    end

    it "requires post access" do
      reply = create(:reply)
      expect(reply.user_id).not_to eq(reply.post.user_id)
      expect(reply.post.visible_to?(reply.user)).to be_true

      reply.post.privacy = Post::PRIVACY_PRIVATE
      reply.post.save
      reply.reload
      expect(reply.post.visible_to?(reply.user)).to eq(false)

      login_as(reply.user)
      delete :destroy, id: reply.id
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You do not have permission to view this post.")
    end

    it "succeeds for reply creator" do
      reply = create(:reply)
      login_as(reply.user)
      delete :destroy, id: reply.id
      expect(response).to redirect_to(post_url(reply.post, page: 1))
      expect(flash[:success]).to eq("Post deleted.")
      expect(Reply.find_by_id(reply.id)).to be_nil
    end

    it "succeeds for admin user" do
      reply = create(:reply)
      login_as(create(:admin_user))
      delete :destroy, id: reply.id
      expect(response).to redirect_to(post_url(reply.post, page: 1))
      expect(flash[:success]).to eq("Post deleted.")
      expect(Reply.find_by_id(reply.id)).to be_nil
    end

    it "respects per_page when redirecting" do
      reply = create(:reply) #p1
      reply = create(:reply, post: reply.post, user: reply.user) #p1
      reply = create(:reply, post: reply.post, user: reply.user) #p2
      reply = create(:reply, post: reply.post, user: reply.user) #p2
      login_as(reply.user)
      delete :destroy, id: reply.id, per_page: 2
      expect(response).to redirect_to(post_url(reply.post, page: 2))
    end

    it "respects per_page when redirecting first on page" do
      reply = create(:reply) #p1
      reply = create(:reply, post: reply.post, user: reply.user) #p1
      reply = create(:reply, post: reply.post, user: reply.user) #p2
      reply = create(:reply, post: reply.post, user: reply.user) #p2
      reply = create(:reply, post: reply.post, user: reply.user) #p3
      login_as(reply.user)
      delete :destroy, id: reply.id, per_page: 2
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
        expect(assigns(:users)).to match_array(User.all)
        expect(assigns(:characters)).to match_array(Character.all)
        expect(assigns(:templates)).to match_array(Template.all)
      end

      it "works logged in" do
        login
        get :search
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Replies')
        expect(assigns(:post)).to be_nil
        expect(assigns(:search_results)).to be_nil
        expect(assigns(:users)).to match_array(User.all)
      end

      it "handles invalid post" do
        get :search, post_id: -1
        expect(response).to have_http_status(200)
        expect(assigns(:page_title)).to eq('Search Replies')
        expect(assigns(:post)).to be_nil
        expect(assigns(:search_results)).to be_nil
        expect(assigns(:users)).to match_array(User.all)
      end

      it "handles valid post" do
        templateless_char = Character.where(template_id: nil).first
        post = create(:post, character: templateless_char, user: templateless_char.user)
        get :search, post_id: post.id
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
        get :search, commit: true
        expect(assigns(:search_results)).to match_array(Reply.all)
      end

      it "filters by author" do
        replies = 4.times.collect do create(:reply) end
        filtered_reply = replies.last
        get :search, commit: true, author_id: filtered_reply.user_id
        expect(assigns(:search_results)).to match_array([filtered_reply])
      end

      it "filters by icon" do
        create(:reply, with_icon: true)
        reply = create(:reply, with_icon: true)
        get :search, commit: true, icon_id: reply.icon_id
        expect(assigns(:search_results)).to match_array([reply])
      end

      it "filters by character" do
        create(:reply, with_character: true)
        reply = create(:reply, with_character: true)
        get :search, commit: true, character_id: reply.character_id
        expect(assigns(:search_results)).to match_array([reply])
      end

      it "filters by string" do
        reply = create(:reply, content: 'contains seagull')
        cap_reply = create(:reply, content: 'Seagull is capital')
        create(:reply, content: 'nope')
        get :search, commit: true, subj_content: 'seagull'
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
        get :search, commit: true, subj_content: '"Forks High"'
        expect(assigns(:search_results)).to match_array([reply])
      end

      it "filters by post" do
        replies = 4.times.collect do create(:reply) end
        filtered_reply = replies.last
        get :search, commit: true, post_id: filtered_reply.post_id
        expect(assigns(:search_results)).to match_array([filtered_reply])
      end

      it "filters by continuity" do
        continuity_post = create(:post, num_replies: 1)
        wrong_post = create(:post, num_replies: 1)
        filtered_reply = continuity_post.replies.last
        get :search, commit: true, board_id: continuity_post.board_id
        expect(assigns(:search_results)).to match_array([filtered_reply])
      end

      it "filters by template" do
        character = create(:template_character)
        templateless_char = create(:character)
        reply = create(:reply, character: character, user: character.user)
        create(:reply, character: templateless_char, user: templateless_char.user)
        get :search, commit: true, template_id: character.template_id
        expect(assigns(:search_results)).to match_array([reply])
      end
    end
  end
end
