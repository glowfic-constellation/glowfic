RSpec.describe "Users" do
  include ActiveJob::TestHelper

  describe "creation" do
    it "creates a new reader-mode user and sends confirmation email" do
      get "/users/sign_up"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Sign Up")
      end

      expect {
        post "/users", params: {
          user: {
            username: "John Doe",
            email: "john.doe@example.com",
            password: "password",
            password_confirmation: "password",
          },
          addition: 14,
          tos: true,
        }
      }.to change { User.count }.by(1)
      expect(DeviseMailer).to have_queue_size_of(1)

      aggregate_failures do
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to be_nil
      end
      follow_redirect!

      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:index)
        expect(flash[:notice]).to eq("A message with a confirmation link has been sent to your email address. Please follow the link to activate your account.")
      end
    end

    it "redirects when logged in" do
      login

      get "/users/sign_up"
      aggregate_failures do
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("You are already signed in.")
      end

      expect {
        post "/users", params: {
          user: {
            username: "John Doe",
            email: "john.doe@example.com",
            password: "password",
            password_confirmation: "password",
          },
          addition: 14,
          tos: true,
        }
      }.not_to change { User.count }

      aggregate_failures do
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("You are already signed in.")
      end
    end
  end

  describe "log in" do
    it "redirects when logged in" do
      login

      get "/users/sign_in"
      aggregate_failures do
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("You are already signed in.")
      end

      post "/users/sign_in", params: {
        user: {
          username: "John Doe",
          password: "password",
          remember_me: true,
        },
      }

      aggregate_failures do
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("You are already signed in.")
      end
    end

    it "requires an existing username" do
      nonusername = 'nonuser'
      expect(User.find_by(username: nonusername)).to be_nil

      post "/users/sign_in", params: {
        user: {
          username: nonusername,
          password: "password",
          remember_me: true,
        },
      }

      expect(flash[:alert]).to eq("Invalid Username or password.")
      expect(controller.send(:logged_in?)).not_to eq(true)
    end

    it "requires unsuspended user" do # TODO: actually implement this behaviour
      user = create(:user, password: "knownknown", role_id: Permissible::SUSPENDED)

      post "/users/sign_in", params: {
        user: {
          username: user.username,
          password: "knownknown",
          remember_me: true,
        },
      }

      expect(flash[:alert]).to eq("You could not be logged in.")
      expect(controller.send(:logged_in?)).not_to eq(true)
    end

    it "disallows logins with old passwords when reset is pending" do
      user = create(:user)
      user.reset_password
      expect(user.reset_password_token).to be_present
      post :create, params: { username: user.username }
      expect(flash[:error]).to eq("The password for this account has been reset. Please check your email.")
      expect(controller.send(:logged_in?)).not_to eq(true)
    end

    it "requires a valid password" do
      password = 'password'
      user = create(:user, password: password)
      post :create, params: { username: user.username, password: password + "-not" }
      expect(flash[:error]).to eq("You have entered an incorrect password.")
      expect(controller.send(:logged_in?)).not_to eq(true)
    end

    it "logs in successfully with salt_uuid" do
      password = 'password'
      user = create(:user, password: password)
      expect(session[:user_id]).to be_nil
      expect(controller.send(:logged_in?)).not_to eq(true)

      post :create, params: { username: user.username, password: password }

      expect(session[:user_id]).to eq(user.id)
      expect(controller.send(:logged_in?)).to eq(true)
      expect(flash[:success]).to eq("You are now logged in as #{user.username}. Welcome back!")
      expect(cookies.signed[:user_id]).to be_nil
    end

    it "logs in successfully without salt_uuid and sets it" do
      password = 'password'
      user = create(:user)
      user.update_columns(salt_uuid: nil, crypted: user.send(:old_crypted_password, password)) # rubocop:disable Rails/SkipsModelValidations
      user.reload
      expect(user.salt_uuid).to be_nil
      expect(session[:user_id]).to be_nil
      expect(controller.send(:logged_in?)).not_to eq(true)

      post :create, params: { username: user.username, password: password }

      expect(session[:user_id]).to eq(user.id)
      expect(controller.send(:logged_in?)).to eq(true)
      expect(flash[:success]).to eq("You are now logged in as #{user.username}. Welcome back!")
      expect(cookies.signed[:user_id]).to be_nil
      expect(user.reload.salt_uuid).not_to be_nil
      expect(user.authenticate(password)).to eq(true)
    end

    it "creates permanent cookies when remember me is provided" do
      password = 'password'
      user = create(:user, password: password)
      expect(cookies.signed[:user_id]).to be_nil
      post :create, params: { username: user.username, password: password, remember_me: true }
      expect(controller.send(:logged_in?)).to eq(true)
      expect(cookies.signed[:user_id]).to eq(user.id)
    end

    it "disallows logins from deleted users" do
      user = create(:user, deleted: true)
      post :create, params: { username: user.username }
      expect(flash[:error]).to eq("That username does not exist.")
      expect(controller.send(:logged_in?)).not_to eq(true)
    end

    it "works when logged out" do
      get :new
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("Sign In")
    end
  end

  describe "log out" do
    it "requires login" do
      delete :destroy
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "logs out" do
      login
      delete :destroy
      expect(controller.send(:logged_in?)).not_to eq(true)
      expect(flash[:success]).to eq("You have been logged out.")
      # TODO test session vars and cookies and redirect
    end
  end
end
