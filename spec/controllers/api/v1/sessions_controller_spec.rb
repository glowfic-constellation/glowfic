RSpec.describe Api::V1::SessionsController do
  describe "POST create" do
    it "requires logout" do
      password = 'password'
      user = create(:user, password: password)
      api_login_as(user)
      post :create, params: { username: user.username, password: password }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You must be logged out to call this endpoint.")
    end

    it "requires an existing username" do
      nonusername = 'nonuser'
      expect(User.find_by(username: nonusername)).to be_nil
      post :create, params: { username: nonusername }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("That username does not exist.")
    end

    it "requires undeleted user" do
      user = create(:user, deleted: true)
      post :create, params: { username: user.username }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("That username does not exist.")
    end

    it "requires unsuspended user" do
      user = create(:user, role_id: Permissible::SUSPENDED)
      post :create, params: { username: user.username }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You could not be logged in.")
    end

    it "disallows logins with old passwords when reset is pending" do
      user = create(:user)
      user.send_reset_password_instructions
      expect(user.reset_password_token).to be_present
      post :create, params: { username: user.username }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("The password for this account has been reset. Please check your email.")
    end

    it "requires a valid password" do
      password = 'password'
      user = create(:user, password: password)
      post :create, params: { username: user.username, password: password + "-not" }
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("You have entered an incorrect password.")
    end

    it "logs in successfully with salt_uuid" do
      password = 'password'
      user = create(:user, password: password)

      post :create, params: { username: user.username, password: password }

      expect(response).to have_http_status(200)
      expect(response.parsed_body).to have_key('token')
      decoded_token = JWT.decode(response.parsed_body['token'], Authentication.secret_key_api)[0]
      expect(decoded_token['user_id']).to eq(user.id)
    end

    it "logs in successfully without salt_uuid and updates to Devise" do
      password = 'password'
      user = create(:user)
      user.update_columns(salt_uuid: nil, legacy_password_hash: user.send(:old_crypted_password, password), encrypted_password: '') # rubocop:disable Rails/SkipsModelValidations
      user.reload
      expect(user.salt_uuid).to be_nil
      expect(user.encrypted_password).to be_empty
      expect(session[:user_id]).to be_nil
      expect(controller.send(:logged_in?)).not_to eq(true)

      post :create, params: { username: user.username, password: password }

      expect(response).to have_http_status(200)
      expect(response.parsed_body).to have_key('token')
      decoded_token = JWT.decode(response.parsed_body['token'], Authentication.secret_key_api)[0]
      expect(decoded_token['user_id']).to eq(user.id)
      expect(user.reload.encrypted_password).not_to be_empty
      expect(user.valid_password?(password)).to eq(true)
    end

    it "logs in successfully without Devise and updates to Devise" do
      password = 'password'
      user = create(:user, salt_uuid: SecureRandom.uuid)
      user.update_columns(legacy_password_hash: user.send(:crypted_password, password), encrypted_password: '') # rubocop:disable Rails/SkipsModelValidations
      user.reload
      expect(user.encrypted_password).to be_empty
      expect(session[:user_id]).to be_nil
      expect(controller.send(:logged_in?)).not_to eq(true)

      post :create, params: { username: user.username, password: password }

      expect(response).to have_http_status(200)
      expect(response.parsed_body).to have_key('token')
      decoded_token = JWT.decode(response.parsed_body['token'], Authentication.secret_key_api)[0]
      expect(decoded_token['user_id']).to eq(user.id)
      expect(user.reload.encrypted_password).not_to be_nil
      expect(user.valid_password?(password)).to eq(true)
    end
  end
end
