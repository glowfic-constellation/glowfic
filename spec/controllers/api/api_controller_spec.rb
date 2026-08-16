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
        expect(response).to have_http_status(422)
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
    let(:client_application) do
      ClientApplication.create!(
        user: user,
        name: "Client Application name",
        url: "http://localhost/",
        callback_url: "http://localhost:3000/callback",
      )
    end

    def oauth_login(token_value)
      request.headers.merge({ Authorization: "Bearer #{token_value}" })
    end

    it "works when a valid access token is provided" do
      token = Oauth2Token.create!(user: user, client_application: client_application)
      oauth_login(token.token)
      get :show, params: { id: 1 }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].size).to eq(3)
    end

    it "does not accept an authorization code as a bearer token" do
      verifier = Oauth2Verifier.create!(user: user, client_application: client_application)
      oauth_login(verifier.code)
      get :index
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token is not valid.")
    end

    it "does not accept an expired access token" do
      token = Oauth2Token.create!(user: user, client_application: client_application, expires_at: 1.hour.ago)
      oauth_login(token.token)
      get :index
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token is not valid.")
    end

    it "does not accept an invalidated access token" do
      token = Oauth2Token.create!(user: user, client_application: client_application)
      token.invalidate!
      oauth_login(token.token)
      get :index
      expect(response).to have_http_status(422)
      expect(response.parsed_body['errors'][0]['message']).to eq("Authorization token is not valid.")
    end
  end
end
