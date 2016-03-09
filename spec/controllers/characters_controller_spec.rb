require "spec_helper"

RSpec.describe CharactersController do
  describe "GET index" do
    it "requires login without an id" do
      get :index
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds with an id" do
      user = create(:user)
      get :index, user_id: user.id
      expect(response.status).to eq(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with missing params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "fails with invalid params" do
      login
      post :create, character: {}
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "succeeds when valid" do
      expect(Character.count).to eq(0)
      test_name = 'Test character'

      login
      post :create, character: {name: test_name}

      expect(Character.count).to eq(1)
      created = Character.first
      expect(created.name).to eq(test_name)

      expect(response.status).to eq(302)
      expect(response.redirect_url).to eq(character_url(created))
      expect(flash[:success]).to eq("Character saved successfully.")
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end
  end

  describe "POST icon" do
    it "requires login" do
      post :icon, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response.status).to eq(302)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end
  end
end
