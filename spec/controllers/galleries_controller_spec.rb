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
    def handle_s3_bucket
      # compensates for developers not having S3 buckets set up locally
      return unless S3_BUCKET.nil?
      struct = Struct.new(:url) do
        def presigned_post(args)
          1
        end
      end
      stub_const("S3_BUCKET", struct.new(''))
    end

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

    it "correctly stubs S3 bucket for devs without local buckets" do
      stub_const("S3_BUCKET", nil)
      login
      get :add, id: 0
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons")
      expect(assigns(:s3_direct_post)).to be_a(Struct)
    end

    it "supports galleryless" do
      handle_s3_bucket
      login
      get :add, id: 0
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons")
      expect(assigns(:s3_direct_post)).not_to be_nil
    end

    it "supports normal gallery" do
      handle_s3_bucket
      gallery = create(:gallery)
      login_as(gallery.user)
      get :add, id: gallery.id
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons: #{gallery.name}")
      expect(assigns(:s3_direct_post)).not_to be_nil
    end

    it "supports existing view for normal gallery" do
      gallery = create(:gallery)
      login_as(gallery.user)
      get :add, id: gallery.id, type: 'existing'
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons: #{gallery.name}")
      expect(assigns(:s3_direct_post)).to be_nil
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

    #TODO: setup_new_icons?

    it "requires valid gallery" do
      login
      post :icon, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq('Gallery could not be found.')
    end

    it "requires your gallery" do
      gallery = create(:gallery)
      login
      post :icon, id: gallery.id
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq('That is not your gallery.')
    end

    context "when adding existing icons" do
      it "doesn't support galleryless" do
        user_id = login
        icon = create(:icon, user_id: user_id)
        gallery = create(:gallery, user_id: user_id, icon_ids: [icon.id])
        expect(gallery.icons).to match_array([icon])

        post :icon, id: 0, image_ids: icon.id.to_s
        expect(response).to redirect_to(galleries_url)
        expect(flash[:error]).to eq('Gallery could not be found.')
      end

      it "skips icons that are not yours" do
        icon = create(:icon)
        gallery = create(:gallery)
        login_as(gallery.user)

        post :icon, id: gallery.id, image_ids: icon.id.to_s
        expect(response).to redirect_to(gallery_path(gallery))
        expect(flash[:success]).to eq('Icons added to gallery successfully.')
        expect(icon.reload.has_gallery).not_to be_true
        expect(gallery.reload.icons).to be_empty
      end

      it "succeeds with galleryless icons" do
        user = create(:user)
        icon1 = create(:icon, user_id: user.id)
        icon2 = create(:icon, user_id: user.id)
        gallery = create(:gallery, user_id: user.id)
        expect(icon1.has_gallery).not_to be_true
        expect(icon2.has_gallery).not_to be_true

        login_as(user)
        post :icon, id: gallery.id, image_ids: "#{icon1.id},#{icon2.id}"
        expect(response).to redirect_to(gallery_path(gallery))
        expect(flash[:success]).to eq('Icons added to gallery successfully.')
        expect(icon1.reload.has_gallery).to be_true
        expect(icon2.reload.has_gallery).to be_true
        expect(gallery.reload.icons).to match_array([icon1, icon2])
      end

      it "succeds with icons from other galleries" do
        user = create(:user)
        icon1 = create(:icon, user_id: user.id)
        icon2 = create(:icon, user_id: user.id)
        gallery1 = create(:gallery, user_id: user.id, icon_ids: [icon1.id, icon2.id])
        gallery2 = create(:gallery, user_id: user.id)
        expect(gallery1.icons).to match_array([icon1, icon2])
        expect(gallery2.icons).to be_empty

        login_as(user)
        post :icon, id: gallery2.id, image_ids: "#{icon1.id},#{icon2.id}"
        expect(response).to redirect_to(gallery_path(gallery2))
        expect(flash[:success]).to eq('Icons added to gallery successfully.')
        expect(icon1.reload.has_gallery).to be_true
        expect(icon2.reload.has_gallery).to be_true
        expect(gallery1.reload.icons).to match_array([icon1, icon2])
        expect(gallery2.reload.icons).to match_array([icon1, icon2])
      end
    end

    context "when adding new icons" do
      it "requires icons" do
        gallery = create(:gallery)
        login_as(gallery.user)
        post :icon, id: gallery.id, icons: []
        expect(response).to render_template(:add)
        expect(flash[:error]).to eq('You have to enter something.')
      end

      it "requires valid icons" do
        gallery = create(:gallery)
        uploaded_icon = create(:uploaded_icon)
        login_as(gallery.user)

        icons = [
          {keyword: 'test1', url: uploaded_icon.url, credit: ''},
          {keyword: '',
          url: 'http://example.com/image3141.png',
          credit: ''},
          {keyword: 'test2', url: '', credit: ''},
          {keyword: 'test3', url: 'fake', credit: ''},
          {keyword: '', url: '', credit: ''}
        ]

        post :icon, id: gallery.id, icons: icons
        expect(response).to render_template(:add)
        expect(flash[:error][:message]).to eq('Your icons could not be saved.')
        expect(assigns(:icons).length).to eq(icons.length-1) # removes blank icons
        expect(assigns(:icons).first[:url]).to be_empty # removes duplicate uploaded icon URLs
        expect(flash.now[:error][:array]).to include(
          "Icon 1: url has already been taken",
          "Icon 2: keyword can't be blank",
          "Icon 3: url can't be blank",
          "Icon 3: url must be an actual fully qualified url (http://www.example.com)"
        )
      end

      it "succeeds with gallery" do
        user = create(:user)
        gallery = create(:gallery, user_id: user.id)
        login_as(user)
        icons = [
          {keyword: 'test1', url: 'http://example.com/image3141.png', credit: 'test1'},
          {keyword: 'test2', url: "https://d1anwqy6ci9o1i.cloudfront.net/users/#{user.id}/icons/nonsense-fakeimg.png"}
        ]

        post :icon, id: gallery.id, icons: icons
        expect(response).to redirect_to(gallery_path(gallery))
        expect(flash[:success]).to eq('Icons saved successfully.')

        gallery.reload
        icon_objs = gallery.icons
        expect(icon_objs.length).to eq(2)

        expect(icon_objs.first.keyword).to eq(icons.first[:keyword])
        expect(icon_objs.first.url).to eq(icons.first[:url])
        expect(icon_objs.first.credit).to eq(icons.first[:credit])

        expect(icon_objs.last.keyword).to eq(icons.last[:keyword])
        expect(icon_objs.last.url).to eq(icons.last[:url])
        expect(icon_objs.last.credit).to be_nil
      end

      it "succeeds with galleryless" do
        user = create(:user)
        login_as(user)
        icons = [
          {keyword: 'test1', url: 'http://example.com/image3142.png', credit: 'test1'},
          {keyword: 'test2', url: "https://d1anwqy6ci9o1i.cloudfront.net/users/#{user.id}/icons/nonsense-fakeimg.png"}
        ]

        post :icon, id: 0, icons: icons
        expect(response).to redirect_to(gallery_path(id: 0))
        expect(flash[:success]).to eq('Icons saved successfully.')

        user.reload
        icon_objs = user.icons.order('keyword ASC')
        expect(icon_objs.length).to eq(2)

        expect(icon_objs.any?(&:has_gallery)).not_to be_true

        expect(icon_objs.first.keyword).to eq(icons.first[:keyword])
        expect(icon_objs.first.url).to eq(icons.first[:url])
        expect(icon_objs.first.credit).to eq(icons.first[:credit])

        expect(icon_objs.last.keyword).to eq(icons.last[:keyword])
        expect(icon_objs.last.url).to eq(icons.last[:url])
        expect(icon_objs.last.credit).to be_nil
      end
    end

    it "has more tests" do
      skip "TODO"
    end
  end
end
