require "spec_helper"

RSpec.describe TagsController do
  describe "GET index" do
    describe ".html" do
      it "succeeds when logged out" do
        get :index
        expect(response.status).to eq(200)
      end

      it "succeeds when logged in" do
        login
        get :index
        expect(response.status).to eq(200)
      end
    end

    describe ".json" do
      shared_examples_for "index.json" do
        it "should support tag search" do
          tag = create(:tag)
          get :index, format: :json, q: tag.name
          expect(response.status).to eq(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
        end

        it "should suuport setting search" do
          tag = create(:setting)
          get :index, format: :json, q: tag.name, t: 'setting'
          expect(response.status).to eq(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
        end

        it "should support content warning search" do
          tag = create(:content_warning)
          get :index, format: :json, q: tag.name, t: 'warning'
          expect(response.status).to eq(200)
          expect(response.json).to have_key('results')
          expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
        end

        it "should handle invalid input" do
          get :index, format: :json, t: 'b'
          expect(response.status).to eq(200)
          json = JSON.parse(response.body)
          expect(json).to have_key('results')
          expect(json['results']).to be_empty
        end
      end

      context "when logged in" do
        before(:each) { login }
        it_behaves_like "index.json"
      end

      context "when logged out" do
        it_behaves_like "index.json"
      end
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Tag could not be saved because of the following problems:")
    end

    it "creates a tag" do
      expect(Tag.first).to be_nil
      user_id = login
      post :create, tag: {name: 'TestTag'}
      tag = Tag.first
      expect(tag).not_to be_nil
      expect(response).to redirect_to(tag_url(tag))
      expect(tag.user_id).to eq(user_id)
    end
  end

  describe "GET show" do
    it "requires valid tag" do
      get :show, id: -1
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "succeeds with valid tag" do
      tag = create(:tag)
      get :show, id: tag.id
      expect(response.status).to eq(200)
    end

    it "succeeds for logged in users with valid tag" do
      tag = create(:tag)
      login
      get :show, id: tag.id
      expect(response.status).to eq(200)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid tag" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "requires permission" do
      tag = create(:tag)
      login
      get :edit, id: tag.id
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "allows admin to edit the tag" do
      tag = create(:tag)
      login_as(create(:admin_user))
      get :edit, id: tag.id
      expect(response.status).to eq(200)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid tag" do
      login
      put :update, id: -1
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "requires permission" do
      login
      tag = create(:tag)
      put :update, id: tag.id
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "requires valid params" do
      tag = create(:tag)
      login_as(create(:admin_user))
      put :update, id: tag.id, tag: {name: nil}
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Tag could not be saved because of the following problems:")
    end

    it "allows admin to update the tag" do
      tag = create(:tag)
      name = tag.name + 'Edited'
      login_as(create(:admin_user))
      put :update, id: tag.id, tag: {name: name}
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:success]).to eq("Tag saved!")
      expect(tag.reload.name).to eq(name)
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid tag" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "requires permission" do
      tag = create(:tag)
      login
      delete :destroy, id: tag.id
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "allows admin to destroy the tag" do
      tag = create(:tag)
      login_as(create(:admin_user))
      delete :destroy, id: tag.id
      expect(response).to redirect_to(tags_path)
      expect(flash[:success]).to eq("Tag deleted.")
    end
  end
end
