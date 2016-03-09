require "spec_helper"

RSpec.describe MessagesController do
  describe "GET index" do
    it "has more tests" do
      skip
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response.status).to eq(302)
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

  describe "PUT update" do
    it "has more tests" do
      skip
    end
  end

  describe "DELETE destroy" do
    it "has more tests" do
      skip
    end
  end

  describe "POST mark" do
    it "has more tests" do
      skip
    end
  end
end
