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
        user = create(:user)
        login_as(user)
        get :index
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
      end
    end

    context "with a user_id" do
      it "does not require login" do
        user = create(:user)
        get :index, user_id: user.id
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
      end

      it "defaults to current user if user id invalid" do
        user = create(:user)
        login_as(user)
        get :index, user_id: -1
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
      end

      it "displays error if user id invalid and logged out" do
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
          skip "how do I handle this"
        end

        it "returns galleryless icons" do
          login
          get :show, id: '0', format: :json
          expect(response.status).to eq(200)
          expect(response.json['name']).to eq('Galleryless')
          expect(response.json['icons']).to be_empty
        end
      end

      context "with normal gallery id" do
        it "requires valid gallery id" do
          skip
        end

        it "requires you to have access to the gallery" do
          skip
        end

        it "displays the gallery" do
          gallery = create(:gallery)
          login_as(gallery.user)
          get :show, id: gallery.id, format: :json
          expect(response.status).to eq(200)
          expect(response.json['name']).to eq(gallery.name)
          expect(response.json['icons']).to be_empty
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
      expect(Gallery.find_by_id(gallery.id)).to be_nil
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
