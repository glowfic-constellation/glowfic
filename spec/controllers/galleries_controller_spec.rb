require "spec_helper"

RSpec.describe GalleriesController do
  describe "GET index" do
    context "without a user_id" do
      it "requires login" do
        get :index
        expect(response).to redirect_to(root_url)
        expect(flash[:error]).to eq("You must be logged in to view that page.")
      end

      it "successfully loads" do
        user = create(:user)
        login_as(user)
        get :index
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq('Your Galleries')
      end
    end

    context "with a user_id" do
      it "does not require login" do
        user = create(:user)
        get :index, user_id: user.id
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq("#{user.username}'s Galleries")
      end

      it "defaults to current user if user id invalid" do
        user = create(:user)
        login_as(user)
        get :index, user_id: -1
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq('Your Galleries')
      end

      it "displays error if user id invalid and logged out" do
        get :index, user_id: -1
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
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
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "shows correct errors on failure" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq('New Gallery')
      expect(flash[:error]).to eq('Your gallery could not be saved.')
    end

    it "succeeds" do
      expect(Gallery.count).to be_zero
      login
      post :create, gallery: {name: 'Test Gallery'}
      expect(Gallery.count).to eq(1)
      expect(response).to redirect_to(gallery_url(assigns(:gallery)))
      expect(flash[:success]).to eq('Gallery saved successfully.')
    end
  end

  describe "GET show" do
    context ".json" do
      context "with zero gallery id" do
        it "requires login" do
          skip "how do I handle json errors"
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
          skip "how do I handle json errors"
        end

        it "requires you to have access to the gallery" do
          skip "how do I handle json errors"
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
      context "with zero gallery id" do
        context "with user id" do
          it "requires valid user" do
            skip "TODO not yet implemented"
          end

          it "succeeds when logged in" do
            user = create(:user)
            gallery_user = create(:user)
            login_as(user)
            get :show, id: '0', user_id: gallery_user.id
            expect(response).to render_template('show')
            expect(assigns(:page_title)).to eq('Galleryless Icons')
            expect(assigns(:user)).to eq(gallery_user)
          end

          it "succeeds when logged out" do
            user = create(:user)
            get :show, id: '0', user_id: user.id
            expect(response).to render_template('show')
            expect(assigns(:page_title)).to eq('Galleryless Icons')
            expect(assigns(:user)).to eq(user)
          end
        end

        context "without user id" do
          it "requires login" do
            get :show, id: '0'
            expect(response).to redirect_to(root_url)
            expect(flash[:error]).to eq("You must be logged in to view that page.")
          end

          it "succeeds when logged in" do
            user = create(:user)
            login_as(user)
            get :show, id: '0'
            expect(response).to render_template('show')
            expect(assigns(:page_title)).to eq('Galleryless Icons')
            expect(assigns(:user)).to eq(user)
          end
        end
      end

      context "with normal gallery id" do
        it "requires valid gallery id" do
          get :show, id: -1
          expect(response).to redirect_to(galleries_url)
          expect(flash[:error]).to eq('Gallery could not be found.')
        end

        it "successfully loads logged out" do
          gallery = create(:gallery)
          get :show, id: gallery.id
          expect(response.status).to eq(200)
        end

        it "successfully loads logged in" do
          gallery = create(:gallery)
          login
          get :show, id: gallery.id
          expect(response.status).to eq(200)
        end
      end
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid gallery" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      get :edit, id: gallery.id
      expect(response).to redirect_to(galleries_url)
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
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid gallery" do
      login
      put :update, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      put :update, id: gallery.id
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("That is not your gallery.")
    end

    it "requires valid params" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      login_as(user)
      put :update, id: gallery.id, gallery: {name: ''}
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("Gallery could not be saved.")
    end

    it "successfully updates" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      login_as(user)
      put :update, id: gallery.id, gallery: {name: 'NewGalleryName'}
      expect(response).to redirect_to(edit_gallery_url(gallery))
      expect(flash[:success]).to eq('Gallery saved.')
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid gallery" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      delete :destroy, id: gallery.id
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("That is not your gallery.")
    end

    it "successfully destroys" do
      user_id = login
      gallery = create(:gallery, user_id: user_id)
      delete :destroy, id: gallery.id
      expect(response).to redirect_to(galleries_url)
      expect(flash[:success]).to eq("Gallery deleted successfully.")
      expect(Gallery.find_by_id(gallery.id)).to be_nil
    end
  end

  describe "GET add" do
    it "requires login" do
      get :add, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid gallery" do
      login
      get :add, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      get :add, id: gallery.id
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("That is not your gallery.")
    end

    it "supports galleryless" do
      login
      get :add, id: 0
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons")
      expect(assigns(:s3_direct_post)).not_to be_nil
    end

    it "supports normal gallery" do
      gallery = create(:gallery)
      login_as(gallery.user)
      get :add, id: gallery.id
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons")
      expect(assigns(:s3_direct_post)).not_to be_nil
    end

    it "supports existing view for normal gallery" do
      gallery = create(:gallery)
      login_as(gallery.user)
      get :add, id: gallery.id, type: 'existing'
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons")
      expect(assigns(:s3_direct_post)).not_to be_nil
    end

    it "doesn't support existing view for galleryless" do
      skip "TODO not yet implemented"
    end
  end

  describe "POST icon" do
    it "requires login" do
      post :icon, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "has more tests" do
      skip "TODO"
    end
  end
end
