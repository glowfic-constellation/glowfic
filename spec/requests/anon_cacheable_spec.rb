RSpec.describe "sharing logged-out pages" do
  let(:user) { create(:user, password: 'testpassword') }
  let!(:post_record) { create(:post) }

  def cache_control
    response.headers['Cache-Control'].to_s
  end

  describe "a logged-out reader" do
    before(:each) { get "/posts/#{post_record.id}" }

    # The whole point: without this the page is never held anywhere.
    it "gets a page a shared cache may hold" do
      expect(cache_control).to include('public')
      expect(cache_control).to include("s-maxage=#{AnonCacheable::SHARED_MAX_AGE.to_i}")
    end

    # A Set-Cookie in a shared cache is handed to the next reader, seating
    # them in somebody else's session. This is the condition that made the
    # page unshareable before, and the one most likely to come back.
    it "is sent no cookie at all" do
      expect(response.headers['Set-Cookie']).to be_blank
    end

    # Belt to the Set-Cookie brace: any correct cache treats a request with a
    # cookie as a different request, so a logged-in reader cannot be served a
    # shared copy even if a CDN rule failed to exclude them.
    it "varies on Cookie" do
      expect(response.headers['Vary'].to_s).to include('Cookie')
    end

    it "still renders the page" do
      expect(response).to have_http_status(200)
    end
  end

  # Forgery protection is off in the test environment, so `csrf_meta_tags` and
  # `form_tag` emit nothing at all by default and an assertion about tokens
  # would pass vacuously. Turn it on for these, and only do GETs inside them.
  describe "the CSRF token on a shareable page" do
    around(:each) do |example|
      was = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
      ActionController::Base.allow_forgery_protection = was
    end

    # Generating a token writes the session, so a shareable page must not
    # carry one. csrf.js fetches it instead.
    it "is left out, because generating it would write the session" do
      get "/posts/#{post_record.id}"
      expect(response.body).not_to include('name="csrf-token"')
      expect(response.body).not_to include('name="authenticity_token"')
    end

    it "leaves the form marked for csrf.js to fill in" do
      get "/posts/#{post_record.id}"
      expect(response.body).to include('data-needs-csrf="true"')
    end

    # A page that is not shareable keeps the token inline as it always did.
    it "is still inline on a page that is not shareable" do
      get "/login"
      expect(response.body).to include('csrf-token')
    end
  end

  describe "a logged-in reader" do
    before(:each) do
      post "/login", params: { username: user.username, password: 'testpassword' }
      get "/posts/#{post_record.id}"
    end

    # If this ever says public, one reader's page can be served to another.
    it "is never given a shareable page" do
      expect(cache_control).not_to include('public')
      expect(cache_control).not_to include('s-maxage')
    end
  end

  describe "returning the reader where they were" do
    it "sends them back to the page they logged in from" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: "/posts/#{post_record.id}" }
      expect(response).to redirect_to("/posts/#{post_record.id}")
    end

    # `return_to` rides in a form that may have come from a shared cache, so
    # it is attacker-controlled input and must never leave the site.
    it "refuses an absolute url" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: 'https://evil.example/phish' }
      expect(response).to redirect_to(root_url)
    end

    # A browser reads a scheme-relative path as another host.
    it "refuses a scheme-relative path" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: '//evil.example/phish' }
      expect(response).to redirect_to(root_url)
    end

    it "refuses a backslash-escaped path" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: '/\\evil.example' }
      expect(response).to redirect_to(root_url)
    end
  end

  describe "the csrf endpoint" do
    it "hands out a token" do
      get "/csrf"
      expect(response).to have_http_status(200)
      expect(response.parsed_body['token']).to be_present
    end

    # It is the one response that must never be held anywhere: a shared token
    # would belong to whoever caused the render.
    it "is never stored" do
      get "/csrf"
      expect(response.headers['Cache-Control'].to_s).to include('no-store')
    end
  end
end
