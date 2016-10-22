require "spec_helper"

RSpec.describe ReportsController do
  describe "GET index" do
    it "succeeds when logged out" do
      get :index
      expect(response.status).to eq(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "GET show" do
    it "requires valid type" do
      get :show, id: -1
      expect(response).to redirect_to(reports_url)
      expect(flash[:error]).to eq("Could not identify the type of report.")
    end

    it "succeeds with daily" do
      get :show, id: 'daily'
      expect(response.status).to eq(200)
    end

    it "succeeds with monthly" do
      get :show, id: 'monthly'
      expect(response.status).to eq(200)
    end
  end
end
