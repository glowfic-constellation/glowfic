RSpec.describe Admin::AdminController do
  include ActiveJob::TestHelper

  let(:mod) { create(:mod_user) }
  let(:admin) { create(:admin_user) }

  describe "GET #index" do
    it "requires login" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      login
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You do not have permission to view that page.")
    end

    it "works for mods" do
      login_as(mod)
      get :index
      expect(response).to have_http_status(200)
    end

    it "works for admins" do
      login_as(admin)
      get :index
      expect(response).to have_http_status(200)
    end
  end
end
