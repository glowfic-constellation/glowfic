require "spec_helper"

RSpec.describe TemplatesController do
  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end
  end

  describe "POST create" do
    it "has more tests" do
      skip
    end
  end

  describe "GET show" do
    it "has more tests" do
      skip
    end
  end

  describe "GET edit" do
    it "has more tests" do
      skip
    end
  end

  describe "PUT update" do
    it "has more tests" do
      skip
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid template" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Template could not be found.")
    end

    it "requires your template" do
      user = create(:user)
      login_as(user)
      template = create(:template)
      delete :destroy, id: template.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("That is not your template.")
    end

    it "succeeds" do
      template = create(:template)
      login_as(template.user)
      delete :destroy, id: template.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:success]).to eq("Template deleted successfully.")
    end
  end
end
