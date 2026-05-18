RSpec.describe AccessToken do
  before(:each) do
    @user = create(:user)
    @app = ClientApplication.create!(user: @user, name: "App", url: "http://example.com", callback_url: "http://example.com/cb")
  end

  it "should be valid" do
    token = AccessToken.create!(client_application: @app, user: @user)
    expect(token).to be_valid
  end

  it "requires a user" do
    token = AccessToken.new(client_application: @app)
    expect(token).not_to be_valid
    expect(token.errors[:user]).to be_present
  end

  it "sets authorized_at on create" do
    token = AccessToken.create!(client_application: @app, user: @user)
    expect(token.authorized_at).to be_present
  end

  it "is authorized after creation" do
    token = AccessToken.create!(client_application: @app, user: @user)
    expect(token).to be_authorized
  end

  it "has a secret" do
    token = AccessToken.create!(client_application: @app, user: @user)
    expect(token.secret).to be_present
  end
end
