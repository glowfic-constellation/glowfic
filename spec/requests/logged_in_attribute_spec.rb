RSpec.describe "logged_in New Relic attribute" do
  def expect_logged_in(value)
    expect(NewRelic::Agent).to receive(:add_custom_attributes).with(logged_in: value).and_call_original
    allow(NewRelic::Agent).to receive(:add_custom_attributes).with(hash_excluding(:logged_in)).and_call_original
  end

  it "is false for a logged-out page view" do
    expect_logged_in(false)
    get '/boards'
  end

  it "is true for a logged-in page view" do
    login
    expect_logged_in(true)
    get '/boards'
  end

  it "is true for an API request with a token" do
    user = create(:user)
    expect_logged_in(true)
    get '/api/v1/boards', headers: { Authorization: "Bearer #{Authentication.generate_api_token(user)}" }
  end
end
