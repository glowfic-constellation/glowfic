RSpec.describe PostsController do
  let(:user) { create(:user) }
  let(:coauthor) { create(:user) }
  let(:user_post) { create(:post, user: user) }

  describe "GET #split" do
    it "requires login" do
      get :split, params: { id: user_post.id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires edit permissions" do
      login
      get :split, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires locked authorship" do
      login_as(user)
      put :update, params: { id: user_post.id, authors_locked: 'false' }
      get :split, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Post must be locked to current authors to be split.")
    end

    it "works for creator if locked" do
      login_as(user)
      put :update, params: { id: user_post.id, authors_locked: 'true' }
      get :split, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end

    it "works for coauthor if locked" do
      login_as(coauthor)
      create(:reply, post: user_post, user: coauthor)
      put :update, params: { id: user_post.id, authors_locked: 'true' }
      get :split, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end
  end

  describe "POST #do_split" do
    let(:replies) { create_list(:reply, 6, post: user_post, user: user) }
    let(:reply) { replies[3] }

    it "requires login" do
      post :do_split, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires edit permissions" do
      login
      post :do_split, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires locked authorship" do
      login_as(user)
      put :update, params: { id: user_post.id, authors_locked: 'false' }
      post :do_split, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Post must be locked to current authors to be split.")
    end

    it "requires reply" do
      login_as(user)
      put :update, params: { id: user_post.id, authors_locked: 'true' }
      post :do_split, params: { id: user_post.id, reply_id: -1 }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Reply could not be found.")
    end

    it "requires subject" do
      login_as(user)
      put :update, params: { id: user_post.id, authors_locked: 'true' }
      post :do_split, params: { id: user_post.id, reply_id: reply.id, subject: "" }
      expect(response).to redirect_to(split_post_url(user_post, reply_id: reply.id))
      expect(flash[:error]).to eq("Subject must not be blank.")
    end

    it "requires reply to be in post" do
      login_as(user)
      other_post_reply = create(:reply, post: create(:post, user: user), user: user)
      put :update, params: { id: user_post.id, authors_locked: 'true' }
      post :do_split, params: { id: user_post.id, reply_id: other_post_reply.id, subject: "" }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Reply given by id is not present in this post.")
    end

    describe "preview" do
      it "loads for author" do
        login_as(user)
        put :update, params: { id: user_post.id, authors_locked: 'true' }
        post :do_split, params: { id: user_post.id, button_preview: 'Preview', reply_id: reply.id, subject: 'new subject' }
        expect(response).to have_http_status(200)
      end

      it "loads for coauthor" do
        login_as(coauthor)
        create(:reply, post: user_post, user: coauthor)
        put :update, params: { id: user_post.id, authors_locked: 'true' }
        post :do_split, params: { id: user_post.id, button_preview: 'Preview', reply_id: reply.id, subject: 'new subject' }
        expect(response).to have_http_status(200)
      end
    end

    describe "perform" do
      it "queues job for author" do
        login_as(coauthor)
        create(:reply, post: user_post, user: coauthor)
        put :update, params: { id: user_post.id, authors_locked: 'true' }
        expect {
          post :do_split, params: { id: user_post.id, reply_id: reply.id, subject: 'new subject' }
        }.to enqueue_job(SplitPostJob).exactly(:once).with(reply.id.to_s, 'new subject')
        expect(response).to redirect_to(post_url(user_post))
      end

      it "queues job for coauthor" do
        login_as(user)
        put :update, params: { id: user_post.id, authors_locked: 'true' }
        expect {
          post :do_split, params: { id: user_post.id, reply_id: reply.id, subject: 'new subject' }
        }.to enqueue_job(SplitPostJob).exactly(:once).with(reply.id.to_s, 'new subject')
        expect(response).to redirect_to(post_url(user_post))
      end
    end
  end
end
