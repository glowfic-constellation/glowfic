RSpec.describe OauthRequest do
  describe ".backchannel?" do
    it "matches the token and OpenID Connect endpoints" do
      expect(OauthRequest.backchannel?('/oauth/token')).to be(true)
      expect(OauthRequest.backchannel?('/oauth/userinfo')).to be(true)
      expect(OauthRequest.backchannel?('/oauth/discovery/keys')).to be(true)
      expect(OauthRequest.backchannel?('/.well-known/openid-configuration')).to be(true)
    end

    it "does not match the pages a user sees in the browser" do
      expect(OauthRequest.backchannel?('/oauth/authorize')).to be(false)
      expect(OauthRequest.backchannel?('/oauth/authorized_applications')).to be(false)
      expect(OauthRequest.backchannel?('/oauth_clients')).to be(false)
      expect(OauthRequest.backchannel?('/posts')).to be(false)
    end

    # A renamed route would quietly lose its exemption.
    it "lists only paths that are routed" do
      routed = Rails.application.routes.routes.map { |route| route.path.spec.to_s.delete_suffix('(.:format)') }
      expect(routed).to include(*OauthRequest::BACKCHANNEL_PATHS)
      expect(routed).to include('/.well-known/openid-configuration')
    end
  end

  describe ".bearer_api?" do
    it "matches an API call with a bearer token" do
      expect(OauthRequest.bearer_api?('/api/v1/posts', 'Bearer abc')).to be(true)
      expect(OauthRequest.bearer_api?('/api/v1/posts', 'bearer abc')).to be(true)
    end

    it "does not match an API call without one" do
      expect(OauthRequest.bearer_api?('/api/v1/posts', nil)).to be(false)
      expect(OauthRequest.bearer_api?('/api/v1/posts', 'Basic abc')).to be(false)
    end

    it "does not match a bearer token sent to a page" do
      expect(OauthRequest.bearer_api?('/posts/1', 'Bearer abc')).to be(false)
    end
  end
end
