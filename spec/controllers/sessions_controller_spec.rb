require "spec_helper"

RSpec.describe SessionsController do
  describe "GET index" do
    it "works when logged out" do
      get :index
      expect(response.status).to eq(200)
      expect(controller.gon.logged_in).not_to be_true
    end

    it "works when logged in" do
      login
      get :index
      expect(response).to have_http_status(200)
      expect(controller.gon.logged_in).to be_true
    end
  end

  describe "GET new" do
    it "works when logged out" do
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("Sign In")
    end

    it "redirects when logged in" do
      login
      get :new
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You are already logged in.")
    end
  end

  describe "POST create" do
    it "redirects when logged in" do
      login
      post :create
      expect(response).to redirect_to(boards_url)
      expect(flash[:error]).to eq("You are already logged in.")
    end

    it "requires an existing username" do
      nonusername = 'nonuser'
      expect(User.find_by(username: nonusername)).to be_nil
      post :create, username: nonusername
      expect(flash[:error]).to eq("That username does not exist.")
      expect(controller.send(:logged_in?)).not_to be_true
    end

    it "disallows logins with old passwords when reset is pending" do
      user = create(:user)
      reset = create(:password_reset, user: user)
      expect(user.password_resets.active.unused).not_to be_empty
      post :create, username: user.username
      expect(flash[:error]).to eq("The password for this account has been reset. Please check your email.")
      expect(controller.send(:logged_in?)).not_to be_true
    end

    it "requires a valid password" do
      password = 'password'
      user = create(:user, password: password)
      post :create, username: user.username, password: password + "-not"
      expect(flash[:error]).to eq("You have entered an incorrect password.")
      expect(controller.send(:logged_in?)).not_to be_true
    end

    it "logs in successfully with salt_uuid" do
      password = 'password'
      user = create(:user, password: password)
      expect(session[:user_id]).to be_nil
      expect(controller.send(:logged_in?)).not_to be_true

      post :create, username: user.username, password: password

      expect(session[:user_id]).to eq(user.id)
      expect(controller.send(:logged_in?)).to be_true
      expect(flash[:success]).to eq("You are now logged in as #{user.username}. Welcome back!")
      expect(cookies.signed[:user_id]).to be_nil
    end

    it "logs in successfully without salt_uuid and sets it" do
      password = 'password'
      user = create(:user)
      user.update_attribute(:salt_uuid, nil)
      user.update_attribute(:crypted, user.send(:old_crypted_password, password))
      user.reload
      expect(user.salt_uuid).to be_nil
      expect(session[:user_id]).to be_nil
      expect(controller.send(:logged_in?)).not_to be_true

      post :create, username: user.username, password: password

      expect(session[:user_id]).to eq(user.id)
      expect(controller.send(:logged_in?)).to be_true
      expect(flash[:success]).to eq("You are now logged in as #{user.username}. Welcome back!")
      expect(cookies.signed[:user_id]).to be_nil
      expect(user.reload.salt_uuid).not_to be_nil
      expect(user.authenticate(password)).to be_true
    end

    it "creates permanent cookies when remember me is provided" do
      password = 'password'
      user = create(:user, password: password)
      expect(cookies.signed[:user_id]).to be_nil
      post :create, username: user.username, password: password, remember_me: true
      expect(controller.send(:logged_in?)).to be_true
      expect(cookies.signed[:user_id]).to eq(user.id)
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "logs out" do
      login
      delete :destroy
      expect(controller.send(:logged_in?)).not_to be_true
      expect(flash[:success]).to eq("You have been logged out.")
      # TODO test session vars and cookies and redirect
    end
  end
end
