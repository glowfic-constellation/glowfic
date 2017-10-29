require "spec_helper"

RSpec.describe IndexPostsController do
  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      user = create(:user)
      index = create(:index)
      expect(index.editable_by?(user)).to eq(false)
      login_as(user)

      get :new, params: { index_id: index.id }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:error]).to eq("You do not have permission to edit this index.")
    end

    it "requires index_id" do
      login
      get :new
      expect(response.status).to redirect_to(indexes_url)
      expect(flash[:error]).to eq("Index could not be found.")
    end

    it "works with index_id" do
      index = create(:index)
      login_as(index.user)
      get :new, params: { index_id: index.id }
      expect(response).to have_http_status(200)
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      user = create(:user)
      index = create(:index)
      expect(index.editable_by?(user)).to eq(false)
      login_as(user)

      post :create, params: { index_post: {index_id: index.id} }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:error]).to eq("You do not have permission to edit this index.")
    end

    it "requires valid post" do
      index = create(:index)
      section = create(:index_section)
      login_as(index.user)
      post :create, params: { index_post: {index_id: index.id, index_section_id: section.id } }
      expect(response).to have_http_status(200)
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Post could not be added to index.")
    end

    it "succeeds" do
      index = create(:index)
      add_post = create(:post)
      login_as(index.user)
      post :create, params: { index_post: { index_id: index.id, post_id: add_post.id } }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:success]).to eq("Post added to index!")
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid index post" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(indexes_url)
      expect(flash[:error]).to eq("Index post could not be found.")
    end

    it "requires permission" do
      index = create(:index)
      index.posts << create(:post, user: index.user)
      login
      delete :destroy, params: { id: index.index_posts.first.id }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:error]).to eq("You do not have permission to edit this index.")
    end

    it "works" do
      index = create(:index)
      index.posts << create(:post, user: index.user)
      login_as(index.user)
      delete :destroy, params: { id: index.index_posts.first.id }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:success]).to eq("Post removed from index.")
      expect(IndexPost.count).to eq(0)
    end
  end
end
