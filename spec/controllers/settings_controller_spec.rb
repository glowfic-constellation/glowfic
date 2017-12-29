require "spec_helper"

RSpec.describe SettingsController do
  describe "GET index" do
    context "with views" do
      render_views
      def create_tags
        setting = create(:setting)
        owned_setting = create(:setting, owned: true)
        [setting, owned_setting]
      end

      it "succeeds when logged out" do
        tags = create_tags
        get :index
        expect(response.status).to eq(200)
        expect(assigns(:settings)).to match_array(tags)
      end

      it "succeeds when logged in" do
        tags = create_tags
        login_as(tags.first.user)
        get :index
        expect(response.status).to eq(200)
        expect(assigns(:settings)).to match_array(tags)
      end
    end
  end

  describe "GET show" do
    it "requires valid tag" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(settings_url)
      expect(flash[:error]).to eq("Setting could not be found.")
    end

    context "with views" do
      render_views

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

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid tag" do
      login
      get :edit, params: { id: -1 }
      expect(response).to redirect_to(settings_url)
      expect(flash[:error]).to eq("Setting could not be found.")
    end

    it "requires permission" do
      tag = create(:setting, owned: true)
      login
      get :edit, params: { id: tag.id }
      expect(response).to redirect_to(setting_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this setting.")
    end

    it "allows admin to edit the tag" do
      tag = create(:setting)
      login_as(create(:admin_user))
      get :edit, params: { id: tag.id }
      expect(response.status).to eq(200)
    end

    it "allows mod to edit the tag" do
      stub_const("Permissible::MOD_PERMS", [:edit_tags])
      tag = create(:setting)
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
      expect(response).to redirect_to(settings_url)
      expect(flash[:error]).to eq("Setting could not be found.")
    end

    it "requires permission" do
      login
      tag = create(:setting, owned: true)
      put :update, params: { id: tag.id }
      expect(response).to redirect_to(setting_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this setting.")
    end

    it "requires valid params" do
      tag = create(:setting)
      login_as(create(:admin_user))
      put :update, params: { id: tag.id, setting: {name: nil} }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Setting could not be saved because of the following problems:")
    end

    it "allows admin to update the tag" do
      tag = create(:setting)
      name = tag.name + 'Edited'
      login_as(create(:admin_user))
      put :update, params: { id: tag.id, setting: {name: name} }
      expect(response).to redirect_to(setting_url(tag))
      expect(flash[:success]).to eq("Setting saved!")
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
      expect(response).to redirect_to(settings_url)
      expect(flash[:error]).to eq("Setting could not be found.")
    end

    it "requires permission" do
      tag = create(:setting, owned: true)
      login
      delete :destroy, params: { id: tag.id }
      expect(response).to redirect_to(setting_url(tag))
      expect(flash[:error]).to eq("You do not have permission to edit this setting.")
    end

    it "allows admin to destroy the tag" do
      tag = create(:setting)
      login_as(create(:admin_user))
      delete :destroy, params: { id: tag.id }
      expect(response).to redirect_to(settings_path)
      expect(flash[:success]).to eq("Setting deleted.")
    end
  end
end
