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
      reply = create(:reply)
      reply = create(:reply, post: reply.post, user: reply.user)
      login_as(reply.user)
      delete :destroy, id: reply.id, per_page: 1
      expect(response).to redirect_to(post_url(reply.post, page: 2))
    end
  end
end
