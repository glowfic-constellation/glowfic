require "spec_helper"

RSpec.describe GalleriesController do
  describe "GET index" do
    context "without a user_id" do
      it "requires login" do
        get :index
        expect(response.status).to eq(302)
        expect(flash[:error]).to eq("You must be logged in to view that page.")
      end

      it "successfully loads" do
        login
        get :index
        expect(response.status).to eq(200)
      end
    end

    context "with a user_id" do
      it "does not require login" do
        skip
      end

      it "defaults to current user if user id invalid" do
        skip
      end
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "successfully loads" do
      login
      get :new
      expect(response.status).to eq(200)
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end
  end

  describe "GET show" do
    context ".json" do
      context "with zero gallery id" do
        it "requires login" do
          skip
        end

        it "returns galleryless icons" do
          skip
        end
      end

      context "with normal gallery id" do
        it "requires valid gallery id" do
          skip
        end

        it "requires you to have access to the gallery" do
          skip
        end
      end
    end

    context ".html" do
      it "requires valid gallery id" do
        skip
      end

      it "successfully loads" do
        gallery = create(:gallery)
        get :show, id: gallery.id
        expect(response.status).to eq(200)
      end
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid gallery" do
      login
      get :edit, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      get :edit, id: gallery.id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("That is not your gallery.")
    end

    it "successfully loads" do
      user_id = login
      gallery = create(:gallery, user_id: user_id)
      get :edit, id: gallery.id
      expect(response.status).to eq(200)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid gallery" do
      login
      put :update, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      put :update, id: gallery.id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("That is not your gallery.")
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

    it "requires valid gallery" do
      login
      delete :destroy, id: -1
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      delete :destroy, id: gallery.id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:error]).to eq("That is not your gallery.")
    end

    it "successfully destroys" do
      user_id = login
      gallery = create(:gallery, user_id: user_id)
      delete :destroy, id: gallery.id
      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(galleries_url)
      expect(flash[:success]).to eq("Gallery deleted successfully.")
      expect(Gallery.find_by_id(gallery)).to be_nil
    end
  end

  describe "GET add" do
    it "requires login" do
      get :add, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip
    end
  end

  describe "POST icon" do
    it "requires login" do
      post :icon, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip
    end
  end
end
