RSpec.describe OauthController do
  describe "token" do
    it "requires a valid client_id" do
      post :token, params: { client_id: "nonexistent" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
