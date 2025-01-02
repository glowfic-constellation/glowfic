RSpec.describe "Users" do
  include ActiveJob::TestHelper

  def session_user_id
    # https://github.com/heartcombo/devise/blob/v4.9.4/lib/devise/models/authenticatable.rb#L237
    # structured as warden.user.user.key => [[record_id], salt]
    session.fetch('warden.user.user.key', []).fetch(0, [])[0]
  end

  def cookie_user_id
    # https://github.com/heartcombo/devise/blob/v4.9.4/lib/devise/models/rememberable.rb#L134
    # structured as remember_user_token => [id, token, generated_at]
    # cookies.signed isn't available here, so we have to decrypt the raw cookie
    if (token = cookies['remember_user_token'])
      jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
      jar[:remember_user_token] = token
      token = (jar.signed['remember_user_token'] || []).fetch(0, [])[0]
    end
    token
  end

  describe "creation" do
    it "creates a new reader-mode user and sends confirmation email" do
      get "/users/sign_up"
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response).to render_template(:new)
        expect(response.body).to include("Sign Up")
      end

      ResqueSpec.reset!
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
        expect(flash[:notice]).to eq(
          "User created. A confirmation link has been emailed to you; use this to activate your account.",
        )
      end
    end

    it "redirects when logged in" do
      login

      get "/users/sign_up"
      aggregate_failures do
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("You are already logged in.")
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
        expect(flash[:alert]).to eq("You are already logged in.")
      end
    end
  end

  describe "log in" do
    it "redirects when logged in" do
      login

      get "/users/sign_in"
      aggregate_failures do
        expect(response).to redirect_to(root_url)
        expect(flash[:alert]).to eq("You are already logged in.")
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
        expect(flash[:alert]).to eq("You are already logged in.")
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

      expect(flash[:alert]).to eq("Invalid username or password.")
      expect(controller.send(:user_signed_in?)).not_to eq(true)
    end

    it "requires unsuspended user" do
      user = create(:user, password: "knownknown", role_id: Permissible::SUSPENDED)

      post "/users/sign_in", params: {
        user: {
          username: user.username,
          password: "knownknown",
          remember_me: true,
        },
      }

      expect(flash[:alert]).to eq("You could not be logged in.")

      get "/"
      expect(controller.send(:user_signed_in?)).not_to eq(true)
    end

    it "still allows logins with old password when reset is pending" do
      user = create(:user, password: 'knownpass')
      user.send_reset_password_instructions
      expect(user.reset_password_token).to be_present
      post "/users/sign_in", params: { user: { username: user.username, password: 'knownpass' } }
      expect(flash[:notice]).to include("You are now logged in")
      expect(controller.send(:user_signed_in?)).to eq(true)
    end

    it "requires a valid password" do
      password = 'password'
      user = create(:user, password: password)
      post "/users/sign_in", params: { user: { username: user.username, password: password + "-not" } }
      expect(flash[:alert]).to eq("Invalid username or password.")
      expect(controller.send(:user_signed_in?)).not_to eq(true)
    end

    it "logs in successfully with salt_uuid" do
      password = 'password'
      user = create(:user, password: password)
      get "/users/sign_in"
      expect(session_user_id).to be_nil
      expect(controller.send(:user_signed_in?)).not_to eq(true)

      post "/users/sign_in", params: { user: { username: user.username, password: password } }

      expect(session_user_id).to eq(user.id)
      expect(controller.send(:user_signed_in?)).to eq(true)
      expect(flash[:notice]).to eq("You are now logged in. Welcome back!")
      expect(cookie_user_id).to be_nil
    end

    it "logs in successfully without salt_uuid and sets Devise password" do
      password = 'password'
      user = create(:user)
      user.update_columns(salt_uuid: nil, legacy_password_hash: user.send(:old_crypted_password, password), encrypted_password: "") # rubocop:disable Rails/SkipsModelValidations
      user.reload
      expect(user.salt_uuid).to be_nil
      expect(user.encrypted_password).to be_empty
      get "/users/sign_in"
      expect(session_user_id).to be_nil
      expect(controller.send(:user_signed_in?)).not_to eq(true)

      post "/users/sign_in", params: { user: { username: user.username, password: password } }

      expect(session_user_id).to eq(user.id)
      expect(controller.send(:user_signed_in?)).to eq(true)
      expect(flash[:notice]).to eq("You are now logged in. Welcome back!")
      expect(cookie_user_id).to be_nil
      expect(user.reload.encrypted_password).not_to be_nil
      expect(user.reload.legacy_password_hash).to be_nil
      expect(user.reload.salt_uuid).to be_nil
      expect(user.valid_password?(password)).to eq(true)
    end

    it "creates permanent cookies when remember me is provided" do
      password = 'password'
      user = create(:user, password: password)
      expect(cookie_user_id).to be_nil
      post "/users/sign_in", params: { user: { username: user.username, password: password, remember_me: true } }
      expect(controller.send(:user_signed_in?)).to eq(true)
      expect(cookie_user_id).to eq(user.id)
    end

    it "disallows logins from deleted users" do
      user = create(:user, deleted: true)
      post "/users/sign_in", params: { user: { username: user.username } }
      expect(flash[:alert]).to eq("Invalid username or password.")
      expect(controller.send(:user_signed_in?)).not_to eq(true)
    end

    it "works when logged out" do
      get "/users/sign_in"
      expect(response.status).to eq(200)
      expect(response.parsed_body.at('title').text).to eq("Sign In")
    end
  end

  describe "log out" do
    it "requires login" do
      delete "/users/sign_out"
      expect(response).to redirect_to(root_url)
      expect(flash[:notice]).to eq("You are already logged out.")
    end

    it "logs out" do
      login
      delete "/users/sign_out"
      expect(controller.send(:user_signed_in?)).not_to eq(true)
      expect(flash[:notice]).to eq("You have been logged out.")
      # TODO test session vars and cookies and redirect
    end
  end
end
