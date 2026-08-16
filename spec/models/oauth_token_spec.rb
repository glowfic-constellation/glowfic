RSpec.describe OauthToken do
  let(:user) { create(:user) }
  let(:app) { ClientApplication.create!(user: user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb") }
  let(:token) { OauthToken.create!(client_application: app, user: user) }

  it "should be valid" do
    expect(token).to be_valid
  end

  it "generates token and secret on create" do
    expect(token.token).to be_present
    expect(token.secret).to be_present
    expect(token.token.length).to eq(40)
    expect(token.secret.length).to eq(40)
  end

  it "generates unique tokens" do
    token2 = OauthToken.create!(client_application: app, user: user)
    expect(token2.token).not_to eq(token.token)
  end

  describe "#invalidated?" do
    it "returns false when not invalidated" do
      expect(token).not_to be_invalidated
    end

    it "returns true when invalidated" do
      token.invalidate!
      expect(token).to be_invalidated
    end
  end

  describe "#invalidate!" do
    it "sets invalidated_at" do
      expect(token.invalidated_at).to be_nil
      token.invalidate!
      expect(token.invalidated_at).to be_present
    end
  end

  describe "#authorized?" do
    it "returns false when not authorized" do
      expect(token.authorized_at).to be_nil
      expect(token).not_to be_authorized
    end

    it "returns false when authorized but invalidated" do
      token.update!(authorized_at: Time.zone.now)
      token.invalidate!
      expect(token).not_to be_authorized
    end

    it "returns true when authorized and not invalidated" do
      token.update!(authorized_at: Time.zone.now)
      expect(token).to be_authorized
    end
  end

  describe ".active" do
    it "includes an authorized token with no expiry" do
      access_token = Oauth2Token.create!(client_application: app, user: user)
      expect(access_token.expires_at).to be_nil
      expect(Oauth2Token.active).to include(access_token)
    end

    it "includes an authorized token that has not yet expired" do
      access_token = Oauth2Token.create!(client_application: app, user: user, expires_at: 1.hour.from_now)
      expect(Oauth2Token.active).to include(access_token)
    end

    it "excludes an expired token" do
      access_token = Oauth2Token.create!(client_application: app, user: user, expires_at: 1.hour.ago)
      expect(Oauth2Token.active).not_to include(access_token)
    end

    it "excludes an invalidated token" do
      access_token = Oauth2Token.create!(client_application: app, user: user)
      access_token.invalidate!
      expect(Oauth2Token.active).not_to include(access_token)
    end

    it "excludes a token that was never authorized" do
      expect(token.authorized_at).to be_nil
      expect(OauthToken.active).not_to include(token)
    end

    it "excludes authorization codes" do
      verifier = Oauth2Verifier.create!(client_application: app, user: user)
      expect(Oauth2Token.active).not_to include(verifier)
    end
  end
end
