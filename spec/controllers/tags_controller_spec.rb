require "spec_helper"

RSpec.describe TagsController do
  describe "GET index" do
    context "with views" do
      render_views
      def create_tags
        # set up sample tags, empty and not
        empty_tag = create(:label)
        tag = create(:label)
        create(:post, labels: [tag])
        setting = create(:setting)
        owned_setting = create(:setting, owned: true)

        empty_group = create(:gallery_group)
        group1 = create(:gallery_group)
        create(:gallery, gallery_groups: [group1])
        [empty_tag, tag, empty_group, group1, setting, owned_setting]
      end

      it "succeeds when logged out" do
        tags = create_tags
        get :index
        expect(response.status).to eq(200)
        tags.reject! { |tag| tag.is_a?(GalleryGroup) }
        expect(assigns(:tags)).to match_array(tags)
      end

      it "succeeds with filter" do
        tags = create_tags
        get :index, params: { view: 'Setting' }
        expect(response).to have_http_status(200)
        expect(assigns(:tags)).to match_array(tags[-2..-1])
        expect(assigns(:page_title)).to eq('Settings')
      end

      it "succeeds when logged in" do
        tags = create_tags
        login_as(tags.first.user)
        get :index
        expect(response.status).to eq(200)
        tags.reject! { |tag| tag.is_a?(GalleryGroup) }
        expect(assigns(:tags)).to match_array(tags)
      end
    end

    it "orders tags by type and then name" do
      tag2 = create(:label, name: "b")
      tag1 = create(:label, name: "a")
      setting1 = create(:setting, name: "a")
      setting2 = create(:setting, owned: true, name: "b")
      warning2 = create(:content_warning, name: "b")
      warning1 = create(:content_warning, name: "a")
      get :index
      expect(assigns(:tags)).to eq([setting1, setting2, tag1, tag2, warning1, warning2])
    end
  end

  describe "GET show" do
    it "requires valid tag" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    context "with views" do
      render_views
      it "succeeds with valid post tag" do
        tag = create(:label)
        post = create(:post, labels: [tag])
        get :show, params: { id: tag.id }
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to match_array([post])
      end

      it "succeeds for logged in users with valid post tag" do
        tag = create(:setting)
        post = create(:post, settings: [tag])
        login
        get :show, params: { id: tag.id }
        expect(response.status).to eq(200)
        expect(assigns(:posts)).to match_array([post])
      end

      it 'succeeds for canons with settings' do
        tag = create(:setting)
        tag.child_settings << create(:setting)
        get :show, params: { id: tag.id }
        expect(response).to have_http_status(200)
      end

      it "succeeds with valid gallery tag" do
        group = create(:gallery_group)
        gallery = create(:gallery, gallery_groups: [group])
        get :show, params: { id: group.id }
        expect(response.status).to eq(200)
        expect(assigns(:galleries)).to match_array([gallery])
      end

      it "succeeds for logged in users with valid gallery tag" do
        group = create(:gallery_group)
        gallery = create(:gallery, gallery_groups: [group])
        login
        get :show, params: { id: group.id }
        expect(response.status).to eq(200)
        expect(assigns(:galleries)).to match_array([gallery])
      end

      context "gallery group" do
        it "succeeds with valid character tag" do
          group = create(:gallery_group)
          character = create(:character, gallery_groups: [group])
          get :show, params: { id: group.id }
          expect(response.status).to eq(200)
          expect(assigns(:characters)).to match_array([character])
        end

        it "succeeds for logged in users with valid character tag" do
          group = create(:gallery_group)
          character = create(:character, gallery_groups: [group])
          login
          get :show, params: { id: group.id }
          expect(response.status).to eq(200)
          expect(assigns(:characters)).to match_array([character])
        end

        it "orders galleries correctly" do
          group = create(:gallery_group)
          gallery2 = create(:gallery, gallery_groups: [group], name: "b")
          gallery3 = create(:gallery, gallery_groups: [group], name: "c")
          gallery1 = create(:gallery, gallery_groups: [group], name: "a")
          get :show, params: { id: group.id }
          expect(response.status).to eq(200)
          expect(assigns(:galleries)).to match_array([gallery1, gallery2, gallery3])
        end
      end

      context "setting" do
        it "succeeds with valid character tag" do
          setting = create(:setting)
          character = create(:character, settings: [setting])
          get :show, params: { id: setting.id }
          expect(response.status).to eq(200)
          expect(assigns(:characters)).to match_array([character])
        end

        it "succeeds for logged in users with valid character tag" do
          setting = create(:setting)
          character = create(:character, settings: [setting])
          login
          get :show, params: { id: setting.id }
          expect(response.status).to eq(200)
          expect(assigns(:characters)).to match_array([character])
        end

        it "succeeds for owned settings" do
          setting = create(:setting, owned: true)
          get :show, params: { id: setting.id }
          expect(response.status).to eq(200)
        end

        it "succeeds for settings without characters" do
          setting = create(:setting)
          get :show, params: { id: setting.id }
          expect(response.status).to eq(200)
          expect(assigns(:characters)).to be_empty
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

    it "requires valid tag" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "requires permission" do
      tag = create(:label, owned: true)
      login
      get :edit, params: { id: tag.id }
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "allows admin to edit the tag" do
      tag = create(:label)
      login_as(create(:admin_user))
      get :edit, params: { id: tag.id }
      expect(response.status).to eq(200)
    end

    it "allows mod to edit the tag" do
      stub_const("Permissible::MOD_PERMS", [:edit_tags])
      tag = create(:label)
      login_as(create(:mod_user))
      get :edit, params: { id: tag.id }
      expect(response.status).to eq(200)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid tag" do
      login
      put :update, params: { id: -1 }
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "requires permission" do
      login
      tag = create(:label, owned: true)
      put :update, params: { id: tag.id }
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "requires valid params" do
      tag = create(:setting)
      login_as(create(:admin_user))
      put :update, params: { id: tag.id, tag: {name: nil} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Tag could not be saved because of the following problems:")
    end

    it "allows admin to update the tag" do
      tag = create(:label)
      name = tag.name + 'Edited'
      login_as(create(:admin_user))
      put :update, params: { id: tag.id, tag: {name: name} }
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:success]).to eq("Tag saved!")
      expect(tag.reload.name).to eq(name)
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid tag" do
      login
      delete :destroy, params: { id: -1 }
      expect(response).to redirect_to(tags_url)
      expect(flash[:error]).to eq("Tag could not be found.")
    end

    it "requires permission" do
      tag = create(:label, owned: true)
      login
      delete :destroy, params: { id: tag.id }
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this tag.")
    end

    it "allows admin to destroy the tag" do
      tag = create(:label)
      login_as(create(:admin_user))
      delete :destroy, params: { id: tag.id }
      expect(response).to redirect_to(tags_path)
      expect(flash[:success]).to eq("Tag deleted.")
    end

    it "handles destroy failure" do
      tag = create(:label)
      login_as(tag.user)
      expect_any_instance_of(Tag).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: tag.id }
      expect(response).to redirect_to(tag_url(tag))
      expect(flash[:error]).to eq({message: "Tag could not be deleted.", array: []})
      expect(Tag.find_by(id: tag.id)).not_to be_nil
    end
  end
end
