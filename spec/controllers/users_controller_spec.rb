require "spec_helper"

RSpec.describe UsersController do
  describe "GET index" do
    it "has more tests" do
      skip
    end
  end

  describe "GET new" do
    it "has more tests" do
      skip
    end
  end

  describe "POST create" do
    it "has more tests" do
      skip
    end
  end

  describe "GET show" do
    it "requires valid user" do
      get :show, id: -1
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "works when logged out" do
      user = create(:user)
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "works when logged in as someone else" do
      user = create(:user)
      login
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "works when logged in as yourself" do
      user = create(:user)
      login_as(user)
      get :show, id: user.id
      expect(response.status).to eq(200)
    end

    it "sets the correct variables" do
      user = create(:user)
      posts = 3.times.collect do create(:post, user: user) end
      create(:post)
      get :show, id: user.id
      expect(assigns(:page_title)).to eq(user.username)
      expect(assigns(:posts).to_a).to match_array(posts)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds" do
      login
      get :edit, id: -1
      expect(response.status).to eq(200)
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

  describe "POST username" do
    it "has more tests" do
      skip
    end
  end

  describe "PUT password" do
    it "has more tests" do
      skip
    end
  end
end
