require "spec_helper"

RSpec.describe TagsController do
  describe "GET index" do
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

  describe "GET show" do
    it "requires valid tag" do
      get :show, id: -1
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "succeeds with valid tag" do
      tag = create(:label)
      get :show, id: tag.id
      expect(response.status).to eq(200)
    end

    it "succeeds for logged in users with valid tag" do
      tag = create(:label)
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
      tag = create(:label)
      login
      get :edit, id: tag.id
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "allows admin to edit the tag" do
      tag = create(:label)
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
      tag = create(:label)
      put :update, id: tag.id
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "requires valid params" do
      tag = create(:label)
      login_as(create(:admin_user))
      put :update, id: tag.id, tag: {name: nil}
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Tag could not be saved because of the following problems:")
    end

    it "allows admin to update the tag" do
      tag = create(:label)
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
      tag = create(:label)
      login
      delete :destroy, id: tag.id
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "allows admin to destroy the tag" do
      tag = create(:label)
      login_as(create(:admin_user))
      delete :destroy, id: tag.id
      expect(response).to redirect_to(tags_path)
      expect(flash[:success]).to eq("Tag deleted.")
    end
  end
end
