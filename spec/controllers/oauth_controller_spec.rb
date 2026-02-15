RSpec.describe OauthController do
  describe "HEAD invalidate" do
    it "returns 410" do
      post :invalidate
      expect(response).to have_http_status(410)
    end
  end
end
