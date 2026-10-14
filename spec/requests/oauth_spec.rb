RSpec.describe 'OAuth authorization' do
  let(:redirect_uri) { 'https://client.example.com/callback' }
  let(:application) { create(:oauth_application, redirect_uri: redirect_uri) }
  let(:verifier) { SecureRandom.urlsafe_base64(48) }
  let(:challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) }
  let(:authorize_params) do
    {
      client_id: application.uid,
      redirect_uri: redirect_uri,
      response_type: 'code',
      state: 'xyz',
      code_challenge: challenge,
      code_challenge_method: 'S256',
    }
  end

  def code_from(location)
    uri = URI.parse(location)
    expect("#{uri.scheme}://#{uri.host}#{uri.path}").to eq(redirect_uri)
    Rack::Utils.parse_query(uri.query)
  end

  def exchange(code, **overrides)
    post '/oauth/token', params: {
      grant_type: 'authorization_code',
      code: code,
      redirect_uri: redirect_uri,
      client_id: application.uid,
      client_secret: application.plaintext_secret,
      code_verifier: verifier,
    }.merge(overrides)
  end

  it 'asks a logged-out user to log in, then returns to the consent page' do
    get '/oauth/authorize', params: authorize_params
    expect(response).to have_http_status(401)
    expect(response).to render_template('sessions/new')

    login
    location = URI.parse(response.location)
    expect(location.path).to eq(oauth_authorization_path)
    expect(Rack::Utils.parse_query(location.query)).to eq(authorize_params.stringify_keys)
  end

  context 'when logged in' do
    let!(:user) { login }

    it 'shows the consent page in the site layout' do
      get '/oauth/authorize', params: authorize_params
      expect(response).to have_http_status(200)
      expect(response).to render_template(layout: 'layouts/application')
    end

    it 'refuses the plain PKCE method' do
      get '/oauth/authorize', params: authorize_params.merge(code_challenge: verifier, code_challenge_method: 'plain')
      aggregate_failures do
        expect(response).not_to have_http_status(200)
        expect(Doorkeeper::AccessGrant.count).to eq(0)
      end
    end

    it 'issues a token the API accepts after the user approves' do
      get '/oauth/authorize', params: authorize_params
      aggregate_failures do
        expect(response).to have_http_status(200)
        expect(response.body).to include(application.name)
        expect(response.body).to include(application.owner.username)
      end

      post '/oauth/authorize', params: authorize_params
      query = code_from(response.location)
      expect(query['state']).to eq('xyz')

      exchange(query['code'])
      expect(response).to have_http_status(200)
      body = response.parsed_body
      expect(body['refresh_token']).to be_present

      reply = create(:reply)
      post '/api/v1/bookmarks', params: { reply_id: reply.id }, headers: { Authorization: "Bearer #{body['access_token']}" }
      expect(response).to have_http_status(200)
      expect(Bookmark.find_by(reply: reply).user).to eq(user)
    end

    it 'issues nothing when the user denies' do
      delete '/oauth/authorize', params: authorize_params
      expect(code_from(response.location)['error']).to eq('access_denied')
      expect(Doorkeeper::AccessGrant.count).to eq(0)
    end

    it 'refuses to redirect to an unregistered URI' do
      get '/oauth/authorize', params: authorize_params.merge(redirect_uri: 'https://evil.example.com/callback')
      expect(response).to have_http_status(400)
      expect(response.body).to include('Authorization Error')
    end

    it 'does not let a code be used twice' do
      post '/oauth/authorize', params: authorize_params
      code = code_from(response.location)['code']
      exchange(code)
      expect(response).to have_http_status(200)
      exchange(code)
      expect(response.parsed_body['error']).to eq('invalid_grant')
    end

    it 'rejects a code with the wrong PKCE verifier' do
      post '/oauth/authorize', params: authorize_params
      exchange(code_from(response.location)['code'], code_verifier: 'wrong' * 10)
      expect(response.parsed_body['error']).to eq('invalid_grant')
    end

    it 'rejects a code with the wrong client secret' do
      post '/oauth/authorize', params: authorize_params
      exchange(code_from(response.location)['code'], client_secret: 'wrong')
      expect(response.parsed_body['error']).to eq('invalid_client')
    end

    it 'issues no token to a user suspended after approving' do
      post '/oauth/authorize', params: authorize_params
      code = code_from(response.location)['code']
      user.update!(role_id: Permissible::SUSPENDED)
      exchange(code)
      aggregate_failures do
        expect(response.parsed_body['error']).to eq('invalid_grant')
        expect(Doorkeeper::AccessToken.where(revoked_at: nil)).not_to exist
      end
    end

    it 'does not refresh a token for a deleted user' do
      post '/oauth/authorize', params: authorize_params
      exchange(code_from(response.location)['code'])
      refresh_token = response.parsed_body['refresh_token']
      user.archive
      post '/oauth/token', params: {
        grant_type: 'refresh_token',
        refresh_token: refresh_token,
        client_id: application.uid,
        client_secret: application.plaintext_secret,
      }
      expect(response.parsed_body['error']).to eq('invalid_grant')
    end

    it 'requires CSRF protection on the consent form' do
      ActionController::Base.allow_forgery_protection = true
      post '/oauth/authorize', params: authorize_params
      expect(response).to redirect_to(root_path)
      expect(Doorkeeper::AccessGrant.count).to eq(0)
    ensure
      ActionController::Base.allow_forgery_protection = false
    end

    it 'lets the user revoke an authorized application' do
      token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: user.id)
      get '/oauth/authorized_applications'
      expect(response.body).to include(application.name)

      delete "/oauth/authorized_applications/#{application.id}"
      expect(token.reload).to be_revoked
    end
  end

  it 'renders the application management pages' do
    user = login
    get edit_user_path(user)
    expect(response.body).to include('Your Applications')

    get '/oauth_clients/new'
    expect(response).to have_http_status(200)

    post '/oauth_clients', params: { application: { name: 'Reader', redirect_uri: redirect_uri, confidential: '1' } }
    created = Doorkeeper::Application.last
    aggregate_failures do
      expect(response).to have_http_status(200)
      expect(response.body).to include(created.uid)
      expect(response.body).to include(oauth_token_url)
      expect(response.body).to include(oauth_discovery_provider_url)
      codes = response.body.scan(/<code>([\w-]+)<\/code>/).flatten
      expect(codes.any? { |code| created.secret_matches?(code) }).to be(true)
    end

    get "/oauth_clients/#{created.id}"
    expect(response.body).to include('Generate a new secret')

    get "/oauth_clients/#{created.id}/edit"
    expect(response).to have_http_status(200)

    get '/oauth_clients'
    expect(response.body).to include('Reader')
  end
end
