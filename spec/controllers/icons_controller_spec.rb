require "spec_helper"

RSpec.describe IconsController do
  describe "DELETE delete_multiple" do
    it "requires login" do
      delete :delete_multiple
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "GET show" do
    it "requires valid icon" do
      get :show, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "successfully loads when logged out" do
      icon = create(:icon)
      get :show, id: icon.id
      expect(response.status).to eq(200)
    end

    it "successfully loads when logged in" do
      login
      icon = create(:icon)
      get :show, id: icon.id
      expect(response.status).to eq(200)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid icon" do
      login
      get :edit, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login
      get :edit, id: create(:icon).id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "successfully loads" do
      user_id = login
      icon = create(:icon, user_id: user_id)
      get :edit, id: icon.id
      expect(response.status).to eq(200)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid icon" do
      login
      put :update, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login
      put :update, id: create(:icon).id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "requires valid params" do
      skip
    end

    it "successfully updates" do
      skip
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid icon" do
      login
      delete :destroy, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login
      delete :destroy, id: create(:icon).id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "successfully destroys" do
      user_id = login
      icon = create(:icon, user_id: user_id)
      delete :destroy, id: icon.id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:success]).to eq("Icon deleted successfully.")
      expect(Icon.find_by_id(icon.id)).to be_nil
    end

    it "successfully goes to gallery if one" do
      icon = create(:icon)
      gallery = create(:gallery, user: icon.user)
      icon.galleries << gallery
      login_as(icon.user)
      delete :destroy, id: icon.id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(gallery_url(gallery))
      expect(flash[:success]).to eq("Icon deleted successfully.")
      expect(Icon.find_by_id(icon.id)).to be_nil
    end
  end

  describe "POST avatar" do
    it "requires login" do
      post :avatar, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid icon" do
      login
      post :avatar, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login
      post :avatar, id: create(:icon).id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "has more tests" do
      skip
    end
  end
end
