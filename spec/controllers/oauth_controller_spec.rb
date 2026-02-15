RSpec.describe OauthController do
  describe "HEAD invalidate" do
    it "returns 410" do
      user = create(:user)
      app = ClientApplication.create!(user: user, name: "Test", url: "http://example.com", callback_url: "http://example.com/cb")
      token = AccessToken.create!(user: user, client_application: app)
      request.headers['Authorization'] = "Bearer #{token.token}"
      post :invalidate
      expect(response).to have_http_status(410)
    end

    it "returns 401 without a valid token" do
      post :invalidate
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
