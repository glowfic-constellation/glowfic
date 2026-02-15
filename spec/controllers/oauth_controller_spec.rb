RSpec.describe OauthController do
  describe "token" do
    it "requires a valid client_id" do
      expect {
        post :token, params: { client_id: "nonexistent" }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context "with valid client application" do
      before(:each) do
        @user = create(:user, password: 'testpassword123')
        @app = ClientApplication.create!(
          user: @user, name: "Test App", url: "http://example.com",
          callback_url: "http://example.com/callback",
        )
      end

      it "rejects invalid client_secret" do
        post :token, params: { client_id: @app.key, client_secret: "wrong" }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("invalid_client")
      end

      it "rejects unsupported grant_type" do
        post :token, params: { client_id: @app.key, client_secret: @app.secret, grant_type: "bogus" }
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["error"]).to eq("unsupported_grant_type")
      end

      it "converts 'none' grant_type to client_credentials" do
        post :token, params: { client_id: @app.key, client_secret: @app.secret, grant_type: "none" }
        expect(response).to have_http_status(:ok)
        token = Oauth2Token.last
        expect(token.user).to eq(@user)
        expect(token.client_application).to eq(@app)
      end

      describe "client_credentials grant" do
        it "creates a token for the app owner" do
          expect {
            post :token, params: { client_id: @app.key, client_secret: @app.secret, grant_type: "client_credentials" }
          }.to change { Oauth2Token.count }.by(1)
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["access_token"]).to be_present
          expect(Oauth2Token.last.user).to eq(@user)
        end

        it "passes scope to token" do
          post :token, params: { client_id: @app.key, client_secret: @app.secret, grant_type: "client_credentials", scope: "read write" }
          expect(response).to have_http_status(:ok)
          expect(Oauth2Token.last.scope).to eq("read write")
        end
      end

      describe "password grant" do
        it "creates a token with valid credentials" do
          post :token, params: {
            client_id: @app.key, client_secret: @app.secret,
            grant_type: "password", username: @user.username, password: "testpassword123",
          }
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["access_token"]).to be_present
          expect(Oauth2Token.last.user).to eq(@user)
        end

        it "rejects invalid credentials" do
          post :token, params: {
            client_id: @app.key, client_secret: @app.secret,
            grant_type: "password", username: @user.username, password: "wrong",
          }
          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)["error"]).to eq("invalid_grant")
        end
      end

      describe "authorization_code grant" do
        it "exchanges a valid code for a token" do
          verifier = Oauth2Verifier.create!(
            client_application: @app, user: @user, scope: "read",
            callback_url: "http://example.com/callback",
          )
          post :token, params: {
            client_id: @app.key, client_secret: @app.secret,
            grant_type: "authorization_code", code: verifier.token,
            redirect_uri: verifier.redirect_url,
          }
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["access_token"]).to be_present
          expect(verifier.reload).to be_invalidated
        end

        it "rejects invalid code" do
          post :token, params: {
            client_id: @app.key, client_secret: @app.secret,
            grant_type: "authorization_code", code: "invalid",
          }
          expect(response).to have_http_status(:bad_request)
        end

        it "rejects mismatched redirect_uri" do
          verifier = Oauth2Verifier.create!(
            client_application: @app, user: @user, scope: "read",
            callback_url: "http://example.com/callback",
          )
          post :token, params: {
            client_id: @app.key, client_secret: @app.secret,
            grant_type: "authorization_code", code: verifier.token,
            redirect_uri: "http://other.com/callback",
          }
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe "test_request" do
    it "succeeds with valid token" do
      user = create(:user)
      app = ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
      token = Oauth2Token.create!(client_application: app, user: user)
      request.headers['Authorization'] = "Bearer #{token.token}"
      get :test_request
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq("Success\n")
    end

    it "rejects request without token" do
      get :test_request
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects invalidated token" do
      user = create(:user)
      app = ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
      token = Oauth2Token.create!(client_application: app, user: user)
      token.invalidate!
      request.headers['Authorization'] = "Bearer #{token.token}"
      get :test_request
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "authorize" do
    context "GET" do
      it "requires login" do
        get :authorize, params: { client_id: "anything" }
        expect(response).to redirect_to(root_url)
        expect(flash[:error]).to eq("You must be logged in to view that page.")
      end

      it "renders authorization form" do
        user = create(:user)
        login_as(user)
        app = ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
        get :authorize, params: { client_id: app.key }
        expect(response).to have_http_status(:ok)
        expect(assigns(:client_application)).to eq(app)
      end
    end

    context "POST" do
      it "redirects to authorizer redirect URI when authorized" do
        user = create(:user)
        login_as(user)
        app = ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
        post :authorize, params: {
          client_id: app.key, response_type: 'code',
          redirect_uri: "http://example.com/cb", authorize: '1',
        }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("http://example.com/cb")
      end

      it "redirects with error when not authorized" do
        user = create(:user)
        login_as(user)
        app = ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
        post :authorize, params: {
          client_id: app.key, response_type: 'code',
          redirect_uri: "http://example.com/cb", authorize: '0',
        }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("access_denied")
      end
    end
  end

  describe "revoke" do
    it "requires login" do
      post :revoke, params: { token: "anything" }
      expect(response).to redirect_to(root_url)
    end

    it "revokes a valid token" do
      user = create(:user)
      login_as(user)
      app = ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
      token = Oauth2Token.create!(client_application: app, user: user)
      post :revoke, params: { token: token.token }
      expect(response).to redirect_to(oauth_clients_url)
      expect(flash[:notice]).to include("You've revoked the token")
      expect(token.reload).to be_invalidated
    end

    it "handles nonexistent token gracefully" do
      user = create(:user)
      login_as(user)
      post :revoke, params: { token: "nonexistent" }
      expect(response).to redirect_to(oauth_clients_url)
      expect(flash[:notice]).to be_nil
    end

    it "does not revoke another user's token" do
      user = create(:user)
      other = create(:user)
      login_as(user)
      app = ClientApplication.create!(user: other, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
      token = Oauth2Token.create!(client_application: app, user: other)
      post :revoke, params: { token: token.token }
      expect(response).to redirect_to(oauth_clients_url)
      expect(token.reload).not_to be_invalidated
    end
  end

  describe "invalidate" do
    it "invalidates the current token" do
      user = create(:user)
      app = ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
      token = Oauth2Token.create!(client_application: app, user: user)
      request.headers['Authorization'] = "Bearer #{token.token}"
      post :invalidate
      expect(response).to have_http_status(:gone)
      expect(token.reload).to be_invalidated
    end

    it "rejects without valid token" do
      post :invalidate
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
