RSpec.describe GalleriesController do
  describe "GET index" do
    context "without a user_id" do
      it "requires login" do
        get :index
        expect(response).to redirect_to(root_url)
        expect(flash[:error]).to eq("You must be logged in to view that page.")
      end

      it "requires full user" do
        login_as(create(:reader_user))
        get :index
        expect(response).to redirect_to(continuities_path)
        expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
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
        get :index, params: { user_id: user.id }
        expect(response.status).to eq(200)
        expect(assigns(:user)).to eq(user)
        expect(assigns(:page_title)).to eq("#{user.username}'s Galleries")
      end

      it "displays error on invalid pages" do
        user = create(:user)
        get :index, params: { user_id: user.id, page: "nvOpzp; AND 1=1" }
        expect(response).to have_http_status(200)
        expect(assigns(:page)).to eq(1)
      end

      it "displays error if user id invalid and logged out" do
        get :index, params: { user_id: -1 }
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end

      it "requires specified user to be full user" do
        user = create(:reader_user)
        get :index, params: { user_id: user.id }
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end

      it "requires specificed user to not be deleted" do
        user = create(:user, deleted: true)
        get :index, params: { user_id: user.id }
        expect(flash[:error]).to eq('User could not be found.')
        expect(response).to redirect_to(root_url)
      end
    end

    it "paginates many galleries" do
      user = create(:user)
      create_list(:gallery, 101, user: user) # rubocop:disable FactoryBot/ExcessiveCreateList
      get :index, params: { user_id: user.id }
      expect(assigns(:galleries).size).to eq(100)
      expect(assigns(:galleries).total_pages).to eq(2)
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      get :new
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create galleries.")
    end

    context "with views" do
      render_views
      it "successfully loads" do
        login
        get :new
        expect(response.status).to eq(200)
      end
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      post :create
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create galleries.")
    end

    context "with views" do
      render_views
      it "keeps variables on failed save" do
        icon = create(:icon)
        group = create(:gallery_group)
        login_as(icon.user)
        post :create, params: { gallery: { gallery_group_ids: [group.id], icon_ids: [icon.id] } }
        expect(response.status).to eq(200)
        expect(response).to render_template(:new)
        expect(assigns(:page_title)).to eq('New Gallery')
        expect(flash[:error][:message]).to eq('Gallery could not be created because of the following problems:')
        expect(flash[:error][:array]).to eq(["Name can't be blank"])
        expect(assigns(:gallery).gallery_groups.map(&:id)).to eq([group.id])
        expect(assigns(:gallery).icon_ids).to eq([icon.id])
      end
    end

    it "does not set icon has_gallery on failure" do
      icon = create(:icon)
      login_as(icon.user)
      post :create, params: { gallery: { icon_ids: [icon.id] } }
      expect(response).to have_http_status(200)
      expect(assigns(:page_title)).to eq('New Gallery')
      expect(flash[:error][:message]).to eq('Gallery could not be created because of the following problems:')
      expect(flash[:error][:array]).to eq(["Name can't be blank"])
      expect(icon.reload.has_gallery).not_to eq(true)
    end

    it "succeeds" do
      expect(Gallery.count).to be_zero
      icon = create(:icon)
      group = create(:gallery_group)
      login_as(icon.user)
      post :create, params: { gallery: { name: 'Test Gallery', icon_ids: [icon.id], gallery_group_ids: [group.id] } }
      expect(Gallery.count).to eq(1)
      gallery = assigns(:gallery).reload
      expect(response).to redirect_to(gallery_url(gallery))
      expect(flash[:success]).to eq('Gallery created.')
      expect(gallery.name).to eq('Test Gallery')
      expect(gallery.icons).to match_array([icon])
      expect(icon.reload.has_gallery).to eq(true)
      expect(gallery.gallery_groups).to match_array([group])
    end

    it "creates new gallery groups" do
      existing_name = create(:gallery_group)
      existing_case = create(:gallery_group)
      tags = [
        '_atag',
        '_atag',
        create(:gallery_group).id,
        '',
        '_' + existing_name.name,
        '_' + existing_case.name.upcase,
      ]
      login
      expect {
        post :create, params: { gallery: { name: 'a', gallery_group_ids: tags } }
      }.to change { GalleryGroup.count }.by(1)
      expect(GalleryGroup.last.name).to eq('atag')
      expect(assigns(:gallery).gallery_groups.count).to eq(4)
    end
  end

  describe "GET show" do
    context "with zero gallery id" do
      context "with user id" do
        it "requires valid user" do
          get :show, params: { id: '0', user_id: -1 }
          expect(response).to redirect_to(root_url)
          expect(flash[:error]).to eq('User could not be found.')
        end

        it "displays error on invalid pages" do
          user = create(:user)
          get :show, params: { id: '0', user_id: user.id, page: "'" }
          expect(response).to render_template('show')
          expect(response).to have_http_status(200)
          expect(assigns(:page)).to eq(1)
        end

        it "requires specified user to be full user" do
          user = create(:reader_user)
          get :index, params: { user_id: user.id }
          expect(flash[:error]).to eq('User could not be found.')
          expect(response).to redirect_to(root_url)
        end

        it "requires specificed user to not be deleted" do
          user = create(:user, deleted: true)
          get :index, params: { user_id: user.id }
          expect(flash[:error]).to eq('User could not be found.')
          expect(response).to redirect_to(root_url)
        end

        it "succeeds when logged in" do
          user = create(:user)
          gallery_user = create(:user)
          login_as(user)
          get :show, params: { id: '0', user_id: gallery_user.id }
          expect(response).to render_template('show')
          expect(assigns(:page_title)).to eq('Galleryless Icons')
          expect(assigns(:user)).to eq(gallery_user)
        end

        it "succeeds when logged out" do
          user = create(:user)
          get :show, params: { id: '0', user_id: user.id }
          expect(response).to render_template('show')
          expect(assigns(:page_title)).to eq('Galleryless Icons')
          expect(assigns(:user)).to eq(user)
        end
      end

      context "without user id" do
        it "requires login" do
          get :show, params: { id: '0' }
          expect(response).to redirect_to(root_url)
          expect(flash[:error]).to eq("You must be logged in to view that page.")
        end

        it "requires full user" do
          login_as(create(:reader_user))
          get :show, params: { id: '0' }
          expect(response).to redirect_to(continuities_path)
          expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
        end

        it "succeeds when logged in" do
          user = create(:user)
          login_as(user)
          get :show, params: { id: '0' }
          expect(response).to render_template('show')
          expect(assigns(:page_title)).to eq('Galleryless Icons')
          expect(assigns(:user)).to eq(user)
        end
      end

      it "paginates large galleryless" do
        user = create(:user)
        create_list(:icon, 101, user: user) # rubocop:disable FactoryBot/ExcessiveCreateList
        get :show, params: { id: '0', user_id: user.id }
        expect(assigns(:icons).size).to eq(100)
        expect(assigns(:icons).total_pages).to eq(2)
      end
    end

    context "with normal gallery id" do
      it "requires valid gallery id logged out" do
        get :show, params: { id: -1 }
        expect(response).to redirect_to(root_url)
        expect(flash[:error]).to eq('Gallery could not be found.')
      end

      it "requires valid gallery id logged in" do
        user_id = login
        get :show, params: { id: -1 }
        expect(response).to redirect_to(user_galleries_url(user_id))
        expect(flash[:error]).to eq('Gallery could not be found.')
      end

      it "successfully loads logged out" do
        gallery = create(:gallery)
        get :show, params: { id: gallery.id }
        expect(response.status).to eq(200)
      end

      it "successfully loads logged in" do
        gallery = create(:gallery)
        login
        get :show, params: { id: gallery.id }
        expect(response.status).to eq(200)
      end

      it "calculates OpenGraph meta" do
        user = create(:user, username: 'user')
        gallery = create(:gallery, name: 'gallery', user: user)
        create_list(:icon, 16, gallery_ids: [gallery.id])
        get :show, params: { id: gallery.id }

        meta_og = assigns(:meta_og)
        expect(meta_og.keys).to match_array([:url, :title, :description])
        expect(meta_og[:url]).to eq(gallery_url(gallery))
        expect(meta_og[:title]).to eq('user » gallery')
        expect(meta_og[:description]).to eq('16 icons')
      end

      it "calculates OpenGraph meta for a gallery with gallery groups" do
        user = create(:user, username: 'user')
        gallery = create(:gallery,
          name: 'gallery',
          user: user,
          gallery_groups: [create(:gallery_group, name: "Tag 1"), create(:gallery_group, name: "Tag 2")],
        )
        create_list(:icon, 16, gallery_ids: [gallery.id])
        get :show, params: { id: gallery.id }

        meta_og = assigns(:meta_og)
        expect(meta_og.keys).to match_array([:url, :title, :description])
        expect(meta_og[:url]).to eq(gallery_url(gallery))
        expect(meta_og[:title]).to eq("user » gallery")
        expect(meta_og[:description]).to eq("16 icons\nTags: Tag 1, Tag 2")
      end

      it "paginates large gallery" do
        gallery = create(:gallery, icon_count: 101)
        get :show, params: { id: gallery.id }
        expect(assigns(:icons).size).to eq(100)
        expect(assigns(:icons).total_pages).to eq(2)
      end
    end

    context "with views" do
      let(:user) { create(:user) }

      render_views

      context "with galleryless" do
        let(:gallery_user) { create(:user) }
        let(:icons) { create_list(:icon, 3, user: gallery_user) }

        it "loads icon view" do
          get :show, params: { id: '0', user_id: gallery_user.id, view: 'icons' }
          expect(response.status).to eq(200)
        end

        it "loads list view" do
          post = create(:post, user: gallery_user, icon: icons[0])
          create(:post, user: gallery_user, icon: icons[1])
          icons.each { |icon| create(:reply, user: gallery_user, post: post, icon: icon) }
          get :show, params: { id: '0', user_id: gallery_user.id, view: 'list' }
          expect(response.status).to eq(200)
          expect(assigns(:times_used).to_a).to match_array([[icons[0].id, 2], [icons[1].id, 2], [icons[2].id, 1]])
          expect(assigns(:posts_used).to_a).to match_array([[icons[0].id, 1], [icons[1].id, 2], [icons[2].id, 1]])
        end
      end

      context "with a gallery" do
        let(:gallery) { create(:gallery, icon_count: 3) }

        it "loads icon view" do
          get :show, params: { id: gallery.id, view: 'icons' }
          expect(response.status).to eq(200)
        end

        it "loads list view" do
          icons = gallery.icons
          post = create(:post, user: gallery.user, icon: icons[0])
          create(:post, user: gallery.user, icon: icons[1])
          icons.each { |icon| create(:reply, user: gallery.user, post: post, icon: icon) }
          get :show, params: { id: gallery.id, view: 'list' }
          expect(response.status).to eq(200)
          expect(assigns(:times_used).to_a).to match_array([[icons[0].id, 2], [icons[1].id, 2], [icons[2].id, 1]])
          expect(assigns(:posts_used).to_a).to match_array([[icons[0].id, 1], [icons[1].id, 2], [icons[2].id, 1]])
        end
      end
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      skip "TODO Currently relies on inability to create galleries"
    end

    it "requires valid gallery" do
      user_id = login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      get :edit, params: { id: gallery.id }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("You do not have permission to modify this gallery.")
    end

    context "with views" do
      render_views
      it "sets relevant fields" do
        user_id = login
        group = create(:gallery_group)
        gallery = create(:gallery, user_id: user_id, gallery_groups: [group])
        get :edit, params: { id: gallery.id }
        expect(response.status).to eq(200)
        expect(assigns(:javascripts)).to include('galleries/editor')
      end
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      skip "TODO Currently relies on inability to create galleries"
    end

    it "requires valid gallery" do
      user_id = login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      put :update, params: { id: gallery.id }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("You do not have permission to modify this gallery.")
    end

    it "requires valid params" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      login_as(user)
      put :update, params: { id: gallery.id, gallery: { name: '' } }
      expect(response).to render_template('edit')
      expect(flash[:error][:message]).to eq("Gallery could not be updated because of the following problems:")
    end

    it "sets right variables on failed save" do
      gallery = create(:gallery, name: 'Example Gallery')
      login_as(gallery.user)
      post :update, params: { id: gallery.id, gallery: { name: '' } }
      expect(response.status).to eq(200)
      expect(response).to render_template(:edit)
      expect(assigns(:page_title)).to eq('Edit Gallery: Example Gallery')
      expect(flash[:error][:message]).to eq('Gallery could not be updated because of the following problems:')
    end

    context "with views" do
      render_views
      it "keeps variables on failed save" do
        user = create(:user)
        gallery = create(:gallery, user: user)
        create(:icon, user: gallery.user) # icon
        group = create(:gallery_group)
        login_as(gallery.user)
        post :update, params: { id: gallery.id, gallery: { name: '', gallery_group_ids: [group.id] } }
        expect(response.status).to eq(200)
        expect(response).to render_template(:edit)
        expect(assigns(:gallery).gallery_groups.map(&:id)).to eq([group.id])
      end
    end

    it "successfully updates" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      group = create(:gallery_group)
      login_as(user)
      put :update, params: { id: gallery.id, gallery: { name: 'NewGalleryName', gallery_group_ids: [group.id] } }
      expect(response).to redirect_to(edit_gallery_url(gallery))
      expect(flash[:success]).to eq('Gallery updated.')
      gallery.reload
      expect(gallery.name).to eq('NewGalleryName')
      expect(gallery.gallery_groups).to match_array([group])
    end

    it "can update a gallery icon" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      icon = create(:icon, user: user)
      newkey = icon.keyword + 'new'
      gallery.icons << icon
      login_as(user)

      icon_attributes = { id: icon.id, keyword: newkey }
      gid = gallery.galleries_icons.first.id
      gallery_icon_attributes = { id: gid, icon_attributes: icon_attributes }

      put :update, params: {
        id: gallery.id,
        gallery: {
          galleries_icons_attributes: { gid.to_s => gallery_icon_attributes },
        },
      }
      expect(response).to redirect_to(edit_gallery_url(gallery))
      expect(flash[:success]).to eq('Gallery updated.')
      expect(icon.reload.keyword).to eq(newkey)
    end

    it "can remove a gallery icon from the gallery" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      icon = create(:icon, user: user)
      gallery.icons << icon
      expect(icon.reload.has_gallery).to eq(true)
      login_as(user)

      icon_attributes = { id: icon.id }
      gid = gallery.galleries_icons.first.id
      gallery_icon_attributes = { id: gid, _destroy: '1', icon_attributes: icon_attributes }

      put :update, params: {
        id: gallery.id,
        gallery: {
          galleries_icons_attributes: { gid.to_s => gallery_icon_attributes },
        },
      }
      expect(response).to redirect_to(edit_gallery_url(gallery))
      expect(flash[:success]).to eq('Gallery updated.')
      expect(gallery.reload.icons).to be_empty
      expect(icon.reload).not_to be_nil
      expect(icon.has_gallery).not_to eq(true)
    end

    it "can delete a gallery icon" do
      user = create(:user)
      gallery = create(:gallery, user: user)
      icon = create(:icon, user: user)
      gallery.icons << icon
      login_as(user)

      icon_attributes = { id: icon.id, _destroy: '1' }
      gid = gallery.galleries_icons.first.id
      gallery_icon_attributes = { id: gid, icon_attributes: icon_attributes }

      put :update, params: {
        id: gallery.id,
        gallery: {
          galleries_icons_attributes: { gid.to_s => gallery_icon_attributes },
        },
      }
      expect(response).to redirect_to(edit_gallery_url(gallery))
      expect(flash[:success]).to eq('Gallery updated.')
      expect(gallery.reload.icons).to be_empty
      expect(Icon.find_by_id(icon.id)).to be_nil
    end

    it "creates new gallery groups" do
      existing_name = create(:gallery_group)
      existing_case = create(:gallery_group)
      gallery = create(:gallery)
      login_as(gallery.user)
      tags = [
        '_atag',
        '_atag',
        create(:gallery_group).id,
        '',
        '_' + existing_name.name,
        '_' + existing_case.name.upcase,
      ]
      expect {
        post :update, params: { id: gallery.id, gallery: { gallery_group_ids: tags } }
      }.to change { GalleryGroup.count }.by(1)
      expect(GalleryGroup.last.name).to eq('atag')
      expect(assigns(:gallery).gallery_groups.count).to eq(4)
    end

    it "orders gallery groups" do
      user = create(:user)
      login_as(user)
      gallery = create(:gallery, user: user)
      group3 = create(:gallery_group, user: user)
      group1 = create(:gallery_group, user: user)
      group2 = create(:gallery_group, user: user)
      post :update, params: {
        id: gallery.id,
        gallery: { gallery_group_ids: [group1, group2, group3].map(&:id) },
      }
      expect(gallery.gallery_groups).to eq([group1, group2, group3])
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      skip "TODO Currently relies on inability to create galleries"
    end

    it "requires valid gallery" do
      user_id = login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      delete :destroy, params: { id: gallery.id }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("You do not have permission to modify this gallery.")
    end

    it "successfully destroys" do
      user_id = login
      gallery = create(:gallery, user_id: user_id)
      delete :destroy, params: { id: gallery.id }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:success]).to eq("Gallery deleted.")
      expect(Gallery.find_by_id(gallery.id)).to be_nil
    end

    it "modifies associations relevantly" do
      user_id = login
      gallery = create(:gallery, user_id: user_id)
      icon = create(:icon, user_id: user_id)
      gallery.icons << icon
      gallery.save!
      expect(icon.reload.has_gallery).to eq(true)
      delete :destroy, params: { id: gallery.id }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:success]).to eq("Gallery deleted.")
      expect(icon.reload.has_gallery).not_to eq(true)
    end

    it "handles destroy failure" do
      gallery = create(:gallery)
      icon = create(:icon, user: gallery.user, galleries: [gallery])
      login_as(gallery.user)

      allow(Gallery).to receive(:find_by).and_call_original
      allow(Gallery).to receive(:find_by).with({ id: gallery.id.to_s }).and_return(gallery)
      allow(gallery).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      expect(gallery).to receive(:destroy!)

      delete :destroy, params: { id: gallery.id }

      expect(response).to redirect_to(gallery_url(gallery))
      expect(flash[:error]).to eq("Gallery could not be deleted.")
      expect(icon.reload.galleries).to eq([gallery])
    end
  end

  describe "GET add" do
    it "requires login" do
      get :add, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      get :add, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create galleries.")
    end

    it "requires valid gallery" do
      user_id = login
      get :add, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("Gallery could not be found.")
    end

    it "requires your gallery" do
      user_id = login
      gallery = create(:gallery)
      expect(gallery.user_id).not_to eq(user_id)
      get :add, params: { id: gallery.id }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq("You do not have permission to modify this gallery.")
    end

    it "supports galleryless" do
      login
      get :add, params: { id: 0 }
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons")
      expect(assigns(:s3_direct_post)).not_to be_nil
    end

    it "supports normal gallery" do
      gallery = create(:gallery)
      login_as(gallery.user)
      get :add, params: { id: gallery.id }
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons: #{gallery.name}")
      expect(assigns(:s3_direct_post)).not_to be_nil
    end

    it "supports existing view for normal gallery" do
      gallery = create(:gallery)
      login_as(gallery.user)
      get :add, params: { id: gallery.id, type: 'existing' }
      expect(response).to render_template('add')
      expect(assigns(:page_title)).to eq("Add Icons: #{gallery.name}")
      expect(assigns(:s3_direct_post)).to be_nil
    end

    it "doesn't support existing view for galleryless" do
      user_id = login
      get :add, params: { id: 0, type: 'existing' }
      expect(response).to redirect_to(user_gallery_path(id: 0, user_id: user_id))
      expect(flash[:error]).to eq('Cannot add existing icons to galleryless. Please remove from existing galleries instead.')
    end

    it "makes sure devs set up their S3 bucket correctly" do
      fake_bucket = instance_double(Aws::S3::Bucket, url: "http://fake-url.example.com/my-bucket")
      stub_const("S3_BUCKET", fake_bucket)
      allow(ENV).to receive(:fetch).with("MINIO_ENDPOINT", nil).and_return("http://invalid-url.example.com/")
      allow(ENV).to receive(:fetch).with("MINIO_ENDPOINT_EXTERNAL", nil).and_return("http://updated-url.example.com/")
      login
      expect { get :add, params: { id: 0 } }.to raise_error(RuntimeError, /couldn't find minio endpoint.*invalid-url.*in.*fake-url.*/)
    end

    it "works with Docker minio mapping for devs" do
      fake_bucket = instance_double(Aws::S3::Bucket, url: "http://old-url.example.com/my-bucket")
      stub_const("S3_BUCKET", fake_bucket)
      allow(ENV).to receive(:fetch).with("MINIO_ENDPOINT", nil).and_return("http://old-url.example.com/")
      allow(ENV).to receive(:fetch).with("MINIO_ENDPOINT_EXTERNAL", nil).and_return("http://updated-url.example.com/")
      expect(fake_bucket).to receive(:presigned_post).with(hash_including(url: "http://updated-url.example.com/my-bucket"))
      login
      get :add, params: { id: 0 }
    end
  end

  describe "POST icon" do
    it "requires login" do
      post :icon, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(create(:reader_user))
      post :icon, params: { id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create galleries.")
    end

    it "requires valid gallery" do
      user_id = login
      post :icon, params: { id: -1 }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq('Gallery could not be found.')
    end

    it "requires your gallery" do
      gallery = create(:gallery)
      user_id = login
      post :icon, params: { id: gallery.id }
      expect(response).to redirect_to(user_galleries_url(user_id))
      expect(flash[:error]).to eq('You do not have permission to modify this gallery.')
    end

    context "when adding existing icons" do
      it "doesn't support galleryless" do
        user_id = login
        icon = create(:icon, user_id: user_id)
        gallery = create(:gallery, user_id: user_id, icon_ids: [icon.id])
        expect(gallery.icons).to match_array([icon])

        post :icon, params: { id: 0, image_ids: icon.id.to_s }
        expect(response).to redirect_to(user_galleries_url(user_id))
        expect(flash[:error]).to eq('Gallery could not be found.')
      end

      it "skips icons that are not yours" do
        icon = create(:icon)
        gallery = create(:gallery)
        login_as(gallery.user)

        post :icon, params: { id: gallery.id, image_ids: icon.id.to_s }
        expect(response).to redirect_to(gallery_path(gallery))
        expect(flash[:success]).to eq('Icons added to gallery.')
        expect(icon.reload.has_gallery).not_to eq(true)
        expect(gallery.reload.icons).to be_empty
      end

      it "skips icons in the gallery" do
        icon = create(:icon)
        gallery = create(:gallery, user: icon.user)
        gallery.icons << icon
        expect(gallery.galleries_icons.count).to eq(1)
        login_as(gallery.user)

        post :icon, params: { id: gallery.id, image_ids: icon.id.to_s }
        expect(response).to redirect_to(gallery_path(gallery))
        expect(flash[:success]).to eq('Icons added to gallery.')
        expect(icon.reload.has_gallery).to eq(true)
        expect(gallery.reload.galleries_icons.count).to eq(1)
      end

      it "succeeds with galleryless icons" do
        user = create(:user)
        icon1 = create(:icon, user_id: user.id)
        icon2 = create(:icon, user_id: user.id)
        gallery = create(:gallery, user_id: user.id)
        expect(icon1.has_gallery).not_to eq(true)
        expect(icon2.has_gallery).not_to eq(true)

        login_as(user)
        post :icon, params: { id: gallery.id, image_ids: "#{icon1.id},#{icon2.id}" }
        expect(response).to redirect_to(gallery_path(gallery))
        expect(flash[:success]).to eq('Icons added to gallery.')
        expect(icon1.reload.has_gallery).to eq(true)
        expect(icon2.reload.has_gallery).to eq(true)
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
        post :icon, params: { id: gallery2.id, image_ids: "#{icon1.id},#{icon2.id}" }
        expect(response).to redirect_to(gallery_path(gallery2))
        expect(flash[:success]).to eq('Icons added to gallery.')
        expect(icon1.reload.has_gallery).to eq(true)
        expect(icon2.reload.has_gallery).to eq(true)
        expect(gallery1.reload.icons).to match_array([icon1, icon2])
        expect(gallery2.reload.icons).to match_array([icon1, icon2])
      end
    end

    context "when adding new icons" do
      let(:user) { create(:user) }
      let(:gallery) { create(:gallery, user: user) }
      let(:icons) do
        [
          { keyword: 'test1', url: 'http://example.com/image3141.png', credit: 'test1' },
          { keyword: 'test2', url: "https://d1anwqy6ci9o1i.cloudfront.net/users/#{user.id}/icons/nonsense-fakeimg.png" },
        ]
      end

      before(:each) { login_as(user) }

      it "requires icons" do
        post :icon, params: { id: gallery.id, icons: [] }
        expect(response).to render_template(:add)
        expect(flash[:error]).to eq('You have to enter something.')
      end

      it "requires valid icons" do
        uploaded_icon = create(:uploaded_icon)

        icons = [
          { keyword: 'test1', url: uploaded_icon.url, s3_key: uploaded_icon.s3_key, credit: '' },
          { keyword: '', url: 'http://example.com/image3141.png', credit: '' },
          { keyword: 'test2', url: '', credit: '' },
          { keyword: 'test3', url: 'fake', credit: '' },
          { keyword: '', url: '', credit: '' },
        ]

        post :icon, params: { id: gallery.id, icons: icons }
        expect(response).to render_template(:add)
        expect(flash[:error][:message]).to eq('Icons could not be saved because of the following problems:')
        expect(assigns(:icons).length).to eq(icons.length - 1) # removes blank icons
        expect(assigns(:icons).first[:url]).to be_empty # removes not-yours uploaded icon URLs
        expect(flash.now[:error][:array]).to match_array([
          "Icon 1: url is invalid",
          "Icon 2: keyword can't be blank",
          "Icon 3: url can't be blank",
          "Icon 3: url must be an actual fully qualified url (http://www.example.com)",
          "Icon 4: url must be an actual fully qualified url (http://www.example.com)",
        ])
      end

      it "succeeds with gallery" do
        post :icon, params: { id: gallery.id, icons: icons }
        expect(response).to redirect_to(gallery_path(gallery))
        expect(flash[:success]).to eq('Icons saved.')

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
        post :icon, params: { id: 0, icons: icons }
        expect(response).to redirect_to(user_gallery_path(id: 0, user_id: user.id))
        expect(flash[:success]).to eq('Icons saved.')

        user.reload
        icon_objs = user.icons.ordered
        expect(icon_objs.length).to eq(2)

        expect(icon_objs.any?(&:has_gallery)).not_to eq(true)

        expect(icon_objs.first.keyword).to eq(icons.first[:keyword])
        expect(icon_objs.first.url).to eq(icons.first[:url])
        expect(icon_objs.first.credit).to eq(icons.first[:credit])

        expect(icon_objs.last.keyword).to eq(icons.last[:keyword])
        expect(icon_objs.last.url).to eq(icons.last[:url])
        expect(icon_objs.last.credit).to be_nil
      end

      it "handles save failure" do
        icon = build(:icon, user: user)
        icon.assign_attributes(icons[0])
        allow(Icon).to receive(:new).and_call_original
        allow(Icon).to receive(:new).with(hash_including(icons[0])).and_return(icon)
        allow(icon).to receive(:save).and_return(false)

        post :icon, params: { id: gallery.id, icons: icons }

        expect(flash[:error][:message]).to eq('Icons could not be saved because of the following problems:')
        expect(flash[:error][:array]).to eq(['Icon 1 could not be saved.'])

        gallery.reload
        expect(gallery.icons).to be_empty
      end

      it "handles save failure with errors" do
        icon = build(:icon, user: user)
        icon.assign_attributes(icons[0])
        allow(Icon).to receive(:new).and_call_original
        allow(Icon).to receive(:new).with(hash_including(icons[0])).and_return(icon)
        expect(icon).to receive(:save) do
          icon.errors.add(:url, :invalid)
          false
        end

        post :icon, params: { id: gallery.id, icons: icons }

        expect(flash[:error][:message]).to eq('Icons could not be saved because of the following problems:')
        expect(flash[:error][:array]).to eq(['Icon 1: url is invalid'])

        gallery.reload
        expect(gallery.icons).to be_empty
      end
    end

    it "has more tests" do
      skip "TODO"
    end
  end
end
