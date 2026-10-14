RSpec.describe 'OpenID Connect' do
  let(:redirect_uri) { 'https://client.example.com/callback' }
  let(:application) { create(:oauth_application, redirect_uri: redirect_uri) }
  let(:issuer) { Doorkeeper::OpenidConnect.configuration.issuer }
  let(:verifier) { SecureRandom.urlsafe_base64(48) }
  let(:challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) }

  let(:authorize_params) do
    {
      client_id: application.uid,
      redirect_uri: redirect_uri,
      response_type: 'code',
      scope: 'openid profile',
      state: 'xyz',
      nonce: 'n-0S6_WzA2Mj',
      code_challenge: challenge,
      code_challenge_method: 'S256',
    }
  end

  def redirect_query
    expect(response.location).to start_with(redirect_uri)
    Rack::Utils.parse_query(URI.parse(response.location).query)
  end

  def authorize(**overrides)
    post '/oauth/authorize', params: authorize_params.merge(overrides).compact
    redirect_query['code']
  end

  def exchange(code, **overrides)
    post '/oauth/token', params: {
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: redirect_uri,
      client_id: application.uid,
      client_secret: application.plaintext_secret,
      code_verifier: verifier,
    }.merge(overrides).compact
    response.parsed_body
  end

  def verified_claims(id_token)
    get '/oauth/discovery/keys'
    jwks = JWT::JWK::Set.new(response.parsed_body)
    JWT.decode(id_token, nil, true, algorithms: ['RS256'], jwks: jwks, iss: issuer, verify_iss: true,
      aud: application.uid, verify_aud: true,).first
  end

  describe 'discovery' do
    it 'describes the provider' do
      get '/.well-known/openid-configuration'
      expect(response).to have_http_status(200)
      config = response.parsed_body
      aggregate_failures do
        expect(config['issuer']).to eq(issuer)
        expect(config['authorization_endpoint']).to eq(oauth_authorization_url)
        expect(config['token_endpoint']).to eq(oauth_token_url)
        expect(config['userinfo_endpoint']).to eq(oauth_userinfo_url)
        expect(config['jwks_uri']).to eq(oauth_discovery_keys_url)
        expect(config['scopes_supported']).to match_array(['api', 'openid', 'profile'])
        expect(config['response_types_supported']).to eq(['code'])
        expect(config['grant_types_supported']).to match_array(['authorization_code', 'refresh_token'])
        expect(config['subject_types_supported']).to eq(['public'])
        expect(config['id_token_signing_alg_values_supported']).to eq(['RS256'])
        expect(config['code_challenge_methods_supported']).to eq(['S256'])
        expect(config['claims_supported']).to include('sub', 'preferred_username', 'name', 'profile')
        expect(config['claims_supported']).not_to include('email')
      end
    end

    it 'publishes the signing key' do
      get '/oauth/discovery/keys'
      expect(response).to have_http_status(200)
      key = response.parsed_body['keys'].sole
      aggregate_failures do
        expect(key).to include('kty' => 'RSA', 'use' => 'sig', 'alg' => 'RS256')
        expect(key['kid']).to be_present
        expect(key).not_to have_key('d')
      end
    end
  end

  it 'answers prompt=none with login_required when logged out' do
    get '/oauth/authorize', params: authorize_params.merge(prompt: 'none')
    expect(redirect_query['error']).to eq('login_required')
  end

  context 'when logged in' do
    let!(:user) { login }

    it 'returns an ID token whose claims verify against the published keys' do
      body = exchange(authorize)
      expect(response).to have_http_status(200)
      expect(body['scope']).to eq('openid profile')

      claims = verified_claims(body['id_token'])
      aggregate_failures do
        expect(claims['sub']).to eq(user.id.to_s)
        expect(claims['preferred_username']).to eq(user.username)
        expect(claims['name']).to eq(user.username)
        expect(claims['profile']).to eq("#{issuer}/users/#{user.id}")
        expect(claims['nonce']).to eq('n-0S6_WzA2Mj')
        expect(claims).not_to have_key('email')
      end
    end

    it 'returns the user from the userinfo endpoint' do
      token = exchange(authorize)['access_token']
      get '/oauth/userinfo', headers: { Authorization: "Bearer #{token}" }
      expect(response).to have_http_status(200)
      expect(response.parsed_body).to eq({
        'sub'                => user.id.to_s,
        'preferred_username' => user.username,
        'name'               => user.username,
        'profile'            => "#{issuer}/users/#{user.id}",
      })
    end

    it 'leaves out the profile claims without the profile scope' do
      body = exchange(authorize(scope: 'openid'))
      expect(verified_claims(body['id_token']).keys).not_to include('preferred_username', 'name', 'profile')

      get '/oauth/userinfo', headers: { Authorization: "Bearer #{body['access_token']}" }
      expect(response.parsed_body).to eq({ 'sub' => user.id.to_s })
    end

    it 'does not grant the openid scope unless it is requested' do
      body = exchange(authorize(scope: nil))
      aggregate_failures do
        expect(body['scope']).to eq('api')
        expect(body).not_to have_key('id_token')
      end

      get '/oauth/userinfo', headers: { Authorization: "Bearer #{body['access_token']}" }
      expect(response).to have_http_status(403)
    end

    it 'does not let an openid token use the API' do
      token = exchange(authorize)['access_token']
      post '/api/v1/bookmarks', params: { reply_id: create(:reply).id }, headers: { Authorization: "Bearer #{token}" }
      expect(response).to have_http_status(422)
      expect(Bookmark.count).to eq(0)
    end

    it 'lists the requested permissions on the consent page' do
      get '/oauth/authorize', params: authorize_params
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).to include('Log you in with your Glowfic account')
        expect(response.body).to include('See your username and profile link')
        expect(response.body).not_to include('Glowfic API')
      end
    end

    it 'answers prompt=login with login_required' do
      get '/oauth/authorize', params: authorize_params.merge(prompt: 'login')
      expect(redirect_query['error']).to eq('login_required')
    end

    it 'works for a public client with PKCE and no secret' do
      application.update!(confidential: false)
      body = exchange(authorize, client_secret: nil)
      expect(response).to have_http_status(200)
      expect(verified_claims(body['id_token'])['sub']).to eq(user.id.to_s)
    end

    it 'returns an ID token when the access token is refreshed' do
      refresh_token = exchange(authorize)['refresh_token']
      body = exchange(nil, grant_type: 'refresh_token', refresh_token: refresh_token, code_verifier: nil, redirect_uri: nil)
      expect(response).to have_http_status(200)
      expect(verified_claims(body['id_token'])['sub']).to eq(user.id.to_s)
    end

    it 'does not identify a suspended user' do
      token = exchange(authorize)['access_token']
      user.update!(role_id: Permissible::SUSPENDED)
      get '/oauth/userinfo', headers: { Authorization: "Bearer #{token}" }
      expect(response).to have_http_status(401)
    end

    it 'does not identify a deleted user' do
      token = exchange(authorize)['access_token']
      user.archive
      get '/oauth/userinfo', headers: { Authorization: "Bearer #{token}" }
      expect(response).to have_http_status(401)
    end
  end
end
