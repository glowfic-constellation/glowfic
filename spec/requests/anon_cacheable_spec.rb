RSpec.describe "sharing logged-out pages" do
  let(:user) { create(:user, password: 'testpassword') }
  let!(:post_record) { create(:post) }

  def cache_control
    response.headers['Cache-Control'].to_s
  end

  describe "a logged-out reader" do
    before(:each) { get "/posts/#{post_record.id}" }

    it "gets a page a shared cache may hold" do
      expect(cache_control).to include('public')
      expect(cache_control).to include("s-maxage=#{AnonCacheable::SHARED_MAX_AGE.to_i}")
    end

    it "is sent no cookie at all" do
      expect(response.headers['Set-Cookie']).to be_blank
    end

    it "varies on Cookie" do
      expect(response.headers['Vary'].to_s).to include('Cookie')
    end

    it "still renders the page" do
      expect(response).to have_http_status(200)
    end
  end

  # Forgery protection is off in tests; turn it on so token assertions mean something.
  describe "the CSRF token on a shareable page" do
    around(:each) do |example|
      was = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
      ActionController::Base.allow_forgery_protection = was
    end

    it "is left out, because generating it would write the session" do
      get "/posts/#{post_record.id}"
      expect(response.body).not_to include('name="csrf-token"')
      expect(response.body).not_to include('name="authenticity_token"')
    end

    # The test environment skips the ToS unless force_tos is set.
    it "is left out of the ToS form a cookieless visitor sees" do
      get "/posts/#{post_record.id}", params: { force_tos: 1 }
      expect(response.body).to include('id="tos_form"')
      expect(response.body).not_to include('name="authenticity_token"')
      expect(response.headers['Set-Cookie']).to be_blank
      expect(cache_control).to include('public')
    end

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

    it "refuses an absolute url" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: 'https://evil.example/phish' }
      expect(response).to redirect_to(root_url)
    end

    it "refuses a scheme-relative path" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: '//evil.example/phish' }
      expect(response).to redirect_to(root_url)
    end

    it "refuses a backslash-escaped path" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: '/\\evil.example' }
      expect(response).to redirect_to(root_url)
    end

    it "falls back when return_to is not a string" do
      post "/login", params: { username: user.username, password: 'testpassword', return_to: ['/posts'] }
      expect(response).to redirect_to(root_url)
    end
  end

  describe "logging in from a page with no CSRF token" do
    let(:user) { create(:user, password: 'testpassword') }

    around(:each) do |example|
      was = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
      ActionController::Base.allow_forgery_protection = was
    end

    def log_in(headers)
      post "/login", params: { username: user.username, password: 'testpassword' }, headers: headers
    end

    it "works from the site itself" do
      log_in('Sec-Fetch-Site' => 'same-origin')
      expect(flash[:success]).to include('You are now logged in')
    end

    it "is refused from another site" do
      log_in('Sec-Fetch-Site' => 'cross-site')
      expect(flash[:success]).to be_nil
      expect(response).to redirect_to(root_path)
    end

    it "falls back to Origin for a browser without Fetch Metadata" do
      log_in('Origin' => 'https://evil.example')
      expect(flash[:success]).to be_nil
      log_in('Origin' => 'http://www.example.com')
      expect(flash[:success]).to include('You are now logged in')
    end

    it "accepts the ToS only from the site itself" do
      patch "/confirm_tos", headers: { 'Sec-Fetch-Site' => 'cross-site' }
      expect(cookies[:accepted_tos]).to be_blank
      patch "/confirm_tos", headers: { 'Sec-Fetch-Site' => 'same-origin' }
      expect(cookies[:accepted_tos]).to be_present
    end
  end
end
