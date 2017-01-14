require "spec_helper"

RSpec.describe IconsController do
  describe "DELETE delete_multiple" do
    it "requires login" do
      delete :delete_multiple
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires icons" do
      login
      delete :delete_multiple
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("No icons selected.")
    end

    it "requires valid icons" do
      icon = create(:icon)
      icon.destroy
      login
      delete :delete_multiple, marked_ids: [0, '0', 'abc', -1, '-1', icon.id]
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("No icons selected.")
    end

    context "removing icons from a gallery" do
      let(:user) { create(:user) }
      before(:each) { login_as(user) }

      it "requires gallery" do
        icon = create(:icon, user: user)
        delete :delete_multiple, marked_ids: [icon.id], gallery_delete: true
        expect(response).to redirect_to(galleries_url)
        expect(flash[:error]).to eq("Gallery could not be found.")
      end

      it "requires your gallery" do
        icon = create(:icon, user: user)
        gallery = create(:gallery)
        delete :delete_multiple, marked_ids: [icon.id], gallery_id: gallery.id, gallery_delete: true
        expect(response).to redirect_to(galleries_url)
        expect(flash[:error]).to eq("That is not your gallery.")
      end

      it "skips other people's icons" do
        icon = create(:icon)
        gallery = create(:gallery, user: user)
        gallery.icons << icon
        icon.reload
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, marked_ids: [icon.id], gallery_id: gallery.id, gallery_delete: true
        icon.reload
        expect(icon.galleries.count).to eq(1)
      end

      it "removes int ids from gallery" do
        icon = create(:icon, user: user)
        gallery = create(:gallery, user: user)
        gallery.icons << icon
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, marked_ids: [icon.id], gallery_id: gallery.id, gallery_delete: true
        expect(icon.galleries.count).to eq(0)
        expect(response).to redirect_to(gallery_url(gallery))
        expect(flash[:success]).to eq("Icons removed from gallery.")
      end

      it "removes string ids from gallery" do
        icon = create(:icon, user: user)
        gallery = create(:gallery, user: user)
        gallery.icons << icon
        expect(icon.galleries.count).to eq(1)
        delete :delete_multiple, marked_ids: [icon.id.to_s], gallery_id: gallery.id, gallery_delete: true
        expect(icon.galleries.count).to eq(0)
        expect(response).to redirect_to(gallery_url(gallery))
        expect(flash[:success]).to eq("Icons removed from gallery.")
      end
    end

    context "deleting icons from the site" do
      let(:user) { create(:user) }
      before(:each) { login_as(user) }

      it "skips other people's icons" do
        icon = create(:icon)
        delete :delete_multiple, marked_ids: [icon.id]
        icon.reload
      end

      it "removes int ids from gallery" do
        icon = create(:icon, user: user)
        delete :delete_multiple, marked_ids: [icon.id]
        expect(Icon.find_by_id(icon.id)).to be_nil
      end

      it "removes string ids from gallery" do
        icon = create(:icon, user: user)
        icon2 = create(:icon, user: user)
        delete :delete_multiple, marked_ids: [icon.id.to_s, icon2.id.to_s]
        expect(Icon.find_by_id(icon.id)).to be_nil
        expect(Icon.find_by_id(icon2.id)).to be_nil
      end
    end
  end

  describe "GET show" do
    it "requires valid icon" do
      get :show, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "successfully loads when logged out" do
      icon = create(:icon)
      get :show, id: icon.id
      expect(response).to have_http_status(200)
      expect(assigns(:posts)).to be_nil
    end

    it "successfully loads when logged in" do
      login
      icon = create(:icon)
      get :show, id: icon.id
      expect(response).to have_http_status(200)
      expect(assigns(:posts)).to be_nil
    end

    context "post view" do
      let(:icon) { create(:icon) }
      let(:post) { create(:post, icon: icon, user: icon.user) }
      let(:other_post) { create(:post) }
      let(:reply) { create(:reply, icon: icon, user: icon.user, post: other_post) }

      before(:each) do
        create(:post) # should not be found
        post
        reply
      end

      it "loads posts logged in" do
        get :show, id: icon.id, view: 'posts'
        expect(response).to have_http_status(200)
        expect(assigns(:posts)).to match_array([post, other_post])
      end

      it "loads posts logged out" do
        login
        get :show, id: icon.id, view: 'posts'
        expect(response).to have_http_status(200)
        expect(assigns(:posts)).to match_array([post, other_post])
      end
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
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid icon" do
      login
      put :update, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login
      put :update, id: create(:icon).id
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "requires valid params" do
      icon = create(:icon)
      login_as(icon.user)
      put :update, id: icon.id, icon: {url: ''}
      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Your icon could not be saved due to the following problems:")
    end

    it "successfully updates" do
      icon = create(:icon)
      login_as(icon.user)
      new_url = icon.url + '?param'
      put :update, id: icon.id, icon: {url: new_url}
      expect(response).to redirect_to(icon_url(icon))
      expect(flash[:success]).to eq("Icon updated.")
      expect(icon.reload.url).to eq(new_url)
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
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid icon" do
      login
      post :avatar, id: -1
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("Icon could not be found.")
    end

    it "requires your icon" do
      login
      post :avatar, id: create(:icon).id
      expect(response).to redirect_to(galleries_url)
      expect(flash[:error]).to eq("That is not your icon.")
    end

    it "handles save errors" do
      user = create(:user)
      icon = create(:icon, user: user)
      expect(user.avatar_id).to be_nil
      login_as(user)

      expect_any_instance_of(User).to receive(:update_attributes).and_return(false)
      post :avatar, id: icon.id

      expect(response).to redirect_to(icon_url(icon))
      expect(flash[:error]).to eq("Something went wrong.")
      expect(user.reload.avatar_id).to be_nil
    end

    it "works" do
      user = create(:user)
      icon = create(:icon, user: user)
      expect(user.avatar_id).to be_nil
      login_as(user)

      post :avatar, id: icon.id

      expect(response).to redirect_to(icon_url(icon))
      expect(flash[:success]).to eq("Avatar has been set!")
      expect(user.reload.avatar_id).to eq(icon.id)
    end
  end
end
