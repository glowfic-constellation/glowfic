RSpec.describe OauthController, type: :controller do
  include ActiveJob::TestHelper
  before(:each) do
    @user = create(:user)
    login_as(@user)
    @client_application = ClientApplication.create! user: @user, name: "Client Application name", url: "http://localhost/",
      callback_url: "http://localhost:3000/callback"
  end

  describe "GET authorize" do
    it "succeeds" do
      get :authorize, params: { client_id: @client_application.key }
      expect(response.status).to eq(200)
    end

    it "renders template" do
      get :authorize, params: { client_id: @client_application.key }
      expect(response).to render_template('oauth2_authorize')
    end
  end

  describe "POST authorize" do
    it "redirect_to callback_url" do
      post :authorize, params: { authorize: '1', client_id: @client_application.key }
      expect(response).to redirect_to(/\Ahttp:\/\/localhost:3000\/callback/)
    end
  end

  describe "GET test_request" do
    it "renders template" do
      get :test_request
      expect(response.status).to eq(200)
      expect(response.body).to eq("Success\n")
    end
  end

  describe "POST revoke" do
    it "redirects without token" do
      post :revoke
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq(oauth_clients_url)
    end

    it "invalidates token" do
      verifier = Oauth2Verifier.create! client_application: @client_application, user: @user, scope: "account",
        callback_url: @client_application.callback_url
      ProviderAuthorizer.new @user, true,
        { client_id: @client_application.key, scope: 'account', redirect_uri: @client_application.callback_url }
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          code: verifier.code,
          grant_type: "authorization_code",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      post :revoke, params: { token: response.json['access_token'] }
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq(oauth_clients_url)
    end
  end

  describe "POST token" do
    it "should render nothing with no valid token" do
      expect { post :token, params: { token: 999 } }.to raise_error(ActiveRecord::RecordNotFound)
      expect(response.body).to eq("")
    end

    it "should not return access_token" do
      verifier = Oauth2Verifier.create! client_application: @client_application, user: @user, scope: "account",
        callback_url: @client_application.callback_url
      ProviderAuthorizer.new @user, true,
        { client_id: @client_application.key, scope: 'account', redirect_uri: @client_application.callback_url }
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          code: verifier.code,
          grant_type: "foobar",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(400)
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: "something",
          code: verifier.code,
          grant_type: "authorization_code",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(400)
    end

    it "should return access_token" do
      verifier = Oauth2Verifier.create! client_application: @client_application, user: @user, scope: "account",
        callback_url: @client_application.callback_url
      ProviderAuthorizer.new @user, true,
        { client_id: @client_application.key, scope: 'account', redirect_uri: @client_application.callback_url }
      post :token,
        params: {
          username: @user.username,
          password: "password",
          grant_type: "password",
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(200)
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          code: verifier.code,
          grant_type: "password",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(400)
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          code: verifier.code,
          grant_type: "client_credentials",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(200)
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          code: verifier.code,
          grant_type: "none",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(200)
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          grant_type: "authorization_code",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(400)
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          code: verifier.code,
          grant_type: "authorization_code",
          redirect_uri: "some nonsense",
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(400)
      post :token,
        params: {
          client_id: @client_application.key,
          client_secret: @client_application.secret,
          code: verifier.code,
          grant_type: "authorization_code",
          redirect_uri: @client_application.callback_url,
          state: nil,
          permitted: true,
        }
      expect(response.status).to eq(200)
    end
  end
end
