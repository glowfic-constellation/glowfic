RSpec.describe Admin::PostsController do
  include ActiveJob::TestHelper

  let(:mod) { create(:mod_user) }
  let(:admin) { create(:admin_user) }

  describe "GET #regenerate_flat" do
    it "requires login" do
      get :regenerate_flat
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      login
      get :regenerate_flat
      expect(response).to redirect_to(admin_url)
      expect(flash[:error]).to eq("You do not have permission to view that page.")
    end

    it "works for mods" do
      login_as(mod)
      get :regenerate_flat
      expect(response).to have_http_status(200)
    end

    it "works for admins" do
      login_as(admin)
      get :regenerate_flat
      expect(response).to have_http_status(200)
    end
  end

  describe "POST #do_regenerate" do
    before(:each) { create_list(:post, 10) }

    it "requires login" do
      post :do_regenerate
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      login
      post :do_regenerate
      expect(response).to redirect_to(admin_url)
      expect(flash[:error]).to eq("You do not have permission to view that page.")
    end

    it "does nothing by default" do
      login_as(mod)
      expect {
        post :do_regenerate
      }.not_to enqueue_job(GenerateFlatPostJob)

      expect(response).to redirect_to(admin_url)
      expect(flash[:success]).to eq("Flat posts will be regenerated as needed.")
    end

    it "works for mods" do
      login_as(mod)
      expect {
        post :do_regenerate, params: { force: true }
      }.to enqueue_job(GenerateFlatPostJob).exactly(10).times

      expect(response).to redirect_to(admin_url)
      expect(flash[:success]).to eq("Flat posts will be regenerated as needed.")
    end

    it "works for admins" do
      login_as(admin)
      expect {
        post :do_regenerate, params: { force: true }
      }.to enqueue_job(GenerateFlatPostJob).exactly(10).times

      expect(response).to redirect_to(admin_url)
      expect(flash[:success]).to eq("Flat posts will be regenerated as needed.")
    end
  end
end
