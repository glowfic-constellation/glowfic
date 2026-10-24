RSpec.describe Api::ApiController do
  controller do
    before_action :login_required, only: :show

    def index
      render json: { results: [1] } and return unless logged_in?
      render json: { results: [1, 2] }
    end

    def show
      render json: { results: [1, 2, 3] }
    end
  end

  describe "token handling" do
    context "with login_required" do
      it "displays an error if an invalid token is provided" do
        request.headers.merge({ Authorization: "Bearer definitely-invalid" })
        get :show, params: { id: 1 }
        expect(response).to have_http_status(401)
        expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token is not valid.")
      end

      it "displays an error if a malformed JWT is provided" do
        request.headers.merge({ Authorization: "Bearer not.a.jwt" })
        get :show, params: { id: 1 }
        expect(response).to have_http_status(422)
        expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token is not valid.")
      end

      it "displays an error if an expired token is provided" do
        cur_time = Time.zone.now
        Timecop.freeze(cur_time) { api_login }
        Timecop.freeze(cur_time + Authentication::EXPIRY + 3.days) do
          get :show, params: { id: 1 }
          expect(response).to have_http_status(401)
          expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token has expired.")
        end
      end

      it "works when valid token is provided" do
        api_login
        get :show, params: { id: 1 }
        expect(response).to have_http_status(200)
        expect(response.parsed_body['results'].size).to eq(3)
      end
    end

    context "without login_required but with mixed data" do
      it "displays an error if an invalid token is provided" do
        request.headers.merge({ Authorization: "Bearer definitely-invalid" })
        get :index
        expect(response).to have_http_status(401)
        expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token is not valid.")
      end

      it "displays an error if an expired token is provided" do
        cur_time = Time.zone.now
        Timecop.freeze(cur_time) { api_login }
        Timecop.freeze(cur_time + Authentication::EXPIRY + 3.days) do
          get :index
          expect(response).to have_http_status(401)
          expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token has expired.")
        end
      end

      it "displays some data when logged out" do
        get :index
        expect(response).to have_http_status(200)
        expect(response.parsed_body['results'].size).to eq(1)
      end

      it "displays all data when logged in" do
        api_login
        get :index
        expect(response).to have_http_status(200)
        expect(response.parsed_body['results'].size).to eq(2)
      end
    end
  end

  describe "oauth token handling" do
    let(:user) { create(:user) }
    let(:application) { create(:oauth_application) }

    def oauth_login(token)
      request.headers.merge({ Authorization: "Bearer #{token.plaintext_token}" })
    end

    def create_token(**)
      Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id, expires_in: 2.hours, scopes: 'api', **)
    end

    it "works when a valid access token is provided" do
      oauth_login(create_token)
      get :show, params: { id: 1 }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(3)
    end

    it "does not accept a token without the api scope" do
      oauth_login(create_token(scopes: 'openid profile'))
      get :show, params: { id: 1 }
      expect(response).to have_http_status(401)
    end

    it "does not accept an authorization code as a bearer token" do
      grant = Doorkeeper::AccessGrant.create!(application: application, resource_owner_id: user.id,
        expires_in: 10.minutes, redirect_uri: application.redirect_uri,)
      request.headers.merge({ Authorization: "Bearer #{grant.plaintext_token}" })
      get :index
      expect(response).to have_http_status(401)
      expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token is not valid.")
    end

    it "does not accept an expired access token" do
      token = create_token
      Timecop.freeze(3.hours.from_now) do
        oauth_login(token)
        get :index
      end
      expect(response).to have_http_status(401)
    end

    it "does not accept a revoked access token" do
      token = create_token
      token.revoke
      oauth_login(token)
      get :index
      expect(response).to have_http_status(401)
    end

    it "does not authenticate a suspended user" do
      token = create_token
      user.update!(role_id: Permissible::SUSPENDED)
      oauth_login(token)
      get :show, params: { id: 1 }
      expect(response).to have_http_status(401)
    end

    it "does not authenticate a deleted user" do
      token = create_token
      user.archive
      oauth_login(token)
      get :show, params: { id: 1 }
      expect(response).to have_http_status(401)
    end
  end
end
