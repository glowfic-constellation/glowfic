require "spec_helper"

RSpec.describe IndexPostsController do
  let(:klass) { IndexPost }
  let(:parent_klass) { Index }
  let(:redirect_override) { indexes_url }
  let(:parent_redirect_override) { index_url(parent) }

  describe "GET new" do
    let(:klass) { Index }

    include_examples 'GET new with parent validations'

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
      expect(flash[:error]).to eq("You do not have permission to modify this index.")
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

  describe "GET edit" do
    let(:invalid_override) { { id: object.id, index_post: {post_id: nil} } }

    include_examples 'GET edit with parent validations'
  end

  describe "PATCH update" do
    let(:invalid_override) { { id: object.id, index_post: {post_id: nil} } }

    include_examples 'PUT update with parent validations'

    it "works" do
      index = create(:index)
      index.posts << create(:post, user: index.user)
      login_as(index.user)
      expect(index.index_posts.first.description).to be_nil
      patch :update, params: { id: index.index_posts.first.id, index_post: {description: 'some text'} }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:success]).to eq("Index post has been updated.")
      expect(index.index_posts.first.description).to eq('some text')
    end
  end

  describe "DELETE destroy" do
    include_examples 'DELETE destroy with parent validations'

    it "handles destroy failure" do
      index = create(:index)
      post = create(:post, user: index.user)
      index.posts << post
      login_as(index.user)
      expect_any_instance_of(IndexPost).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      index_post = index.index_posts.first
      delete :destroy, params: { id: index_post.id }
      expect(response).to redirect_to(index_url(index))
      expect(flash[:error]).to eq({message: "Post could not be removed from index.", array: []})
      expect(index.reload.index_posts).to eq([index_post])
    end
  end
end
