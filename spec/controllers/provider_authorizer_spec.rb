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
    @provider = ProviderAuthorizer.new @user, true, { state: "some kinda state", response_type: 'code', client_id: @client_application.key, redirect_uri: 'http://localhost:3000/endpoint?some_kind_of_param=true'}
    expect(@provider.redirect_uri).to include('&')
    @provider = ProviderAuthorizer.new @user, true, { response_type: 'code', client_id: @client_application.key, redirect_uri: 'http://localhost:3000/endpoint'}
    expect(@provider.redirect_uri).not_to include('&')
  end
end
