RSpec.describe OauthToken do
  before(:each) do
    @user = create(:user)
    @app = ClientApplication.create!(user: @user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
    @token = OauthToken.create!(client_application: @app, user: @user)
  end

  it "should be valid" do
    expect(@token).to be_valid
  end

  it "generates token and secret on create" do
    expect(@token.token).to be_present
    expect(@token.secret).to be_present
    expect(@token.token.length).to eq(40)
    expect(@token.secret.length).to eq(40)
  end

  it "generates unique tokens" do
    token2 = OauthToken.create!(client_application: @app, user: @user)
    expect(token2.token).not_to eq(@token.token)
  end

  it "validates token uniqueness" do
    dup = OauthToken.new(client_application: @app, user: @user)
    dup.token = @token.token
    dup.secret = SecureRandom.hex(20)
    expect(dup).not_to be_valid
  end

  describe "#invalidated?" do
    it "returns false when not invalidated" do
      expect(@token).not_to be_invalidated
    end

    it "returns true when invalidated" do
      @token.invalidate!
      expect(@token).to be_invalidated
    end
  end

  describe "#invalidate!" do
    it "sets invalidated_at" do
      expect(@token.invalidated_at).to be_nil
      @token.invalidate!
      expect(@token.invalidated_at).to be_present
    end
  end

  describe "#authorized?" do
    it "returns false when not authorized" do
      expect(@token.authorized_at).to be_nil
      expect(@token).not_to be_authorized
    end

    it "returns false when authorized but invalidated" do
      @token.update!(authorized_at: Time.zone.now)
      @token.invalidate!
      expect(@token).not_to be_authorized
    end

    it "returns true when authorized and not invalidated" do
      @token.update!(authorized_at: Time.zone.now)
      expect(@token).to be_authorized
    end
  end
end
