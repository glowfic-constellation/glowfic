RSpec.describe OauthController do
  describe "token" do
    it "requires a valid client_id" do
      expect {
        post :token, params: { client_id: "nonexistent" }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
