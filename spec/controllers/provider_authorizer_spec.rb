RSpec.describe ProviderAuthorizer do
  before(:each) do
    @user = create(:user)
    @client_application = ClientApplication.create! user: @user, name: "Client Application name", url: "http://localhost/",
      callback_url: "http://localhost:3000/callback"
  end

  it "fails if unauthorized" do
    @failed_provider = ProviderAuthorizer.new @user, false, { state: "some kinda state", response_type: 'code', client_id: @client_application.key }
    expect(@failed_provider.response[:error]).to eq("access_denied")
  end

  it "acces_token when token" do
    @provider = ProviderAuthorizer.new @user, true, { state: "some kinda state", response_type: 'token', client_id: @client_application.key }
    expect(@provider.response[:access_token]).not_to be_nil
  end

  it "codes when code" do
    @provider = ProviderAuthorizer.new @user, true, { state: "some kinda state", response_type: 'code', client_id: @client_application.key }
    expect(@provider.response[:code]).not_to be_nil
  end

  it "constructs reasonable redirect_uris" do
    @provider = ProviderAuthorizer.new @user, true,
      { state: "some kinda state", response_type: 'code', client_id: @client_application.key, redirect_uri: 'http://localhost:3000/endpoint?some_kind_of_param=true' }
    expect(@provider.redirect_uri).to include('&')
    @provider = ProviderAuthorizer.new @user, true, { response_type: 'code', client_id: @client_application.key, redirect_uri: 'http://localhost:3000/endpoint' }
    expect(@provider.redirect_uri).not_to include('&')
  end

  it "uses fragment for token response_type" do
    @provider = ProviderAuthorizer.new @user, true,
      { state: "some state", response_type: 'token', client_id: @client_application.key, redirect_uri: 'http://localhost:3000/endpoint' }
    uri = URI.parse(@provider.redirect_uri)
    expect(uri.fragment).to be_present
    expect(uri.fragment).to include('access_token=')
  end

  it "returns unsupported_response_type for unknown type" do
    @provider = ProviderAuthorizer.new @user, true,
      { state: "some state", response_type: 'bogus', client_id: @client_application.key }
    expect(@provider.response[:error]).to eq('unsupported_response_type')
  end

  it "uses app callback_url when no redirect_uri given" do
    @provider = ProviderAuthorizer.new @user, true,
      { state: "some state", response_type: 'code', client_id: @client_application.key }
    expect(@provider.redirect_uri).to start_with(@client_application.callback_url)
  end

  it "encodes response parameters" do
    @provider = ProviderAuthorizer.new @user, true,
      { state: "has spaces", response_type: 'code', client_id: @client_application.key }
    encoded = @provider.encode_response
    expect(encoded).to include('state=has+spaces')
    expect(encoded).to include('code=')
  end
end
