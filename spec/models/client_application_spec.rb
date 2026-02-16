require "#{File.dirname(__FILE__)}/../spec_helper"
RSpec.describe ClientApplication do
  before(:each) do
    @user = create(:user)
    @application = ClientApplication.create! name: "Agree2", url: "http://agree2.com", user: @user, callback_url: "http://test.com/callback"
    @token = Oauth2Token.create! client_application: @application, user: @user
  end

  it "should be valid" do
    expect(@application).to be_valid
  end

  it "should not have errors" do
    expect(@application.errors.full_messages).to eq []
  end

  it "should have key and secret" do
    expect(@application.key).not_to be_nil
    expect(@application.secret).not_to be_nil
  end

  it "should generate unique key and secret" do
    expect(@application.key).not_to eq @application.secret
  end
end
