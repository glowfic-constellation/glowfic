require "spec_helper"

RSpec.describe TemplatesController do
  describe "GET index" do
    context "with user id" do
      it "works when logged out" do
        user = create(:user)
        templates = 3.times.collect do create(:template, user: user) end
        create(:template)
        get :index, user_id: user.id
        expect(response.status).to eq(200)
        expect(assigns(:page_title)).to eq("#{user.username}'s Templates")
        expect(assigns(:templates)).to match_array(templates)
        expect(assigns(:user)).to eq(user)
      end

      it "works when logged in" do
        login
        user = create(:user)
        templates = 3.times.collect do create(:template, user: user) end
        create(:template)
        get :index, user_id: user.id
        expect(response.status).to eq(200)
        expect(assigns(:page_title)).to eq("#{user.username}'s Templates")
        expect(assigns(:templates)).to match_array(templates)
        expect(assigns(:user)).to eq(user)
      end
    end

    context "without user id" do
      it "redirects on logout" do
        get :index
        expect(response).to redirect_to(users_url)
        expect(flash[:error]).to eq("User could not be found.")
      end

      it "works when logged in" do
        user = create(:user)
        templates = 3.times.collect do create(:template, user: user) end
        create(:template)
        login_as(user)
        get :index
        expect(response.status).to eq(200)
        expect(assigns(:page_title)).to eq("Your Templates")
        expect(assigns(:templates)).to match_array(templates)
        expect(assigns(:user)).to eq(user)
      end
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
    it "has more tests" do
      skip
    end
  end
end
