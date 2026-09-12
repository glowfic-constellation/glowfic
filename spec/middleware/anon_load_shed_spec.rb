RSpec.describe AnonLoadShed do
  # rack-timeout is a production-only gem; stub its env key constant where it
  # isn't bundled (dev/test CI) so these specs still exercise the middleware.
  # Where the gem IS present, the real constant is used, guarding against the
  # key drifting from the gem's.
  before(:each) do
    stub_const('Rack::Timeout::ENV_INFO_KEY', 'rack-timeout.info') unless defined?(Rack::Timeout::ENV_INFO_KEY)
  end

  let(:downstream) { ->(_env) { [200, {}, ['ok']] } }
  let(:middleware) { AnonLoadShed.new(downstream) }

  # Headers as the two populations actually send them. Real Chrome announces
  # signed-exchange on navigations; the scrape's forged Chrome UAs do not.
  let(:chrome_ua) { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36' }
  let(:firefox_ua) { 'Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0' }
  let(:real_accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9,application/signed-exchange;v=b3;q=0.7' }
  let(:forged_accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' }

  # `remembered` is the user id the signed `user_id` cookie verifies to, or nil
  # where the cookie is absent, forged or otherwise unverifiable — the jar
  # returns nil for all three, so they are one case from here. Omitting it
  # leaves no jar on the env at all, which is what a bare Rack env looks like.
  def env(wait: nil, user_id: nil, path: '/posts', remembered: :no_jar, accept: nil, user_agent: nil)
    base = {
      Rack::Timeout::ENV_INFO_KEY => wait && Struct.new(:wait).new(wait),
      'rack.session'              => { user_id: user_id },
      'PATH_INFO'                 => path,
      'HTTP_ACCEPT'               => accept,
      'HTTP_USER_AGENT'           => user_agent,
    }
    return base if remembered == :no_jar
    jar = instance_double(ActionDispatch::Cookies::CookieJar, signed: { user_id: remembered })
    base.merge('action_dispatch.cookies' => jar)
  end

  # A request carrying the scrape's signature: a Chrome UA on an HTML
  # navigation that omits the signed-exchange token Chrome always sends.
  def scraper_env(**opts)
    env(accept: forged_accept, user_agent: chrome_ua, **opts)
  end

  it "passes through when there is no wait info (queue depth unknown)" do
    expect(middleware.call(env)).to eq([200, {}, ['ok']])
  end

  it "passes through when wait is under the threshold" do
    expect(middleware.call(env(wait: 1.0))).to eq([200, {}, ['ok']])
  end

  it "passes through logged-in users even when the wait is large" do
    expect(middleware.call(env(wait: 30.0, user_id: 1))).to eq([200, {}, ['ok']])
  end

  it "sheds anonymous users whose request waited longer than the threshold" do
    status, headers, body = middleware.call(env(wait: 10.0))
    expect(status).to eq(503)
    expect(headers).to include('Retry-After' => '30')
    expect(body.first).to match(/busy/i)
  end

  it "still passes through anonymous users right at the threshold boundary" do
    status, = middleware.call(env(wait: AnonLoadShed::WAIT_THRESHOLD_SECONDS - 0.1))
    expect(status).to eq(200)
  end

  it "sheds anonymous users just above the threshold" do
    status, = middleware.call(env(wait: AnonLoadShed::WAIT_THRESHOLD_SECONDS + 0.1))
    expect(status).to eq(503)
  end

  it "never sheds login requests, so logged-out users can still log in under load" do
    status, = middleware.call(env(wait: 30.0, path: '/login'))
    expect(status).to eq(200)
  end

  # A "remember me" reader arrives with a permanent signed cookie and no
  # session, because the session cookie has no expiry and dies with the
  # browser. `check_permanent_user` would restore their session, but it runs in
  # a controller, i.e. after this middleware — so shedding them here is
  # unrecoverable by retrying: the shed response never reaches the controller
  # that would have promoted the cookie.
  it "passes through a remembered user whose session cookie is gone" do
    expect(middleware.call(env(wait: 30.0, user_id: nil, remembered: 7))).to eq([200, {}, ['ok']])
  end

  it "still sheds when the cookie is present but does not verify" do
    status, = middleware.call(env(wait: 30.0, user_id: nil, remembered: nil))
    expect(status).to eq(503)
  end

  it "treats a jar it cannot read as anonymous rather than raising" do
    broken = env(wait: 30.0).merge('action_dispatch.cookies' => Object.new)
    status, = middleware.call(broken)
    expect(status).to eq(503)
  end

  # The scrape and its readers were competing on one threshold, so the shedder
  # split the damage between them rather than aiming it. Scraper-shaped traffic
  # now loses its thread slot an order of magnitude sooner, which is what makes
  # the difference to whoever is queued behind it.
  describe "shedding the scrape before its readers" do
    it "sheds a scraper-shaped request at a wait a reader is still served at" do
      wait = AnonLoadShed::SCRAPER_WAIT_THRESHOLD_SECONDS + 0.1
      expect(middleware.call(env(wait: wait)).first).to eq(200)
      expect(middleware.call(scraper_env(wait: wait)).first).to eq(503)
    end

    it "serves scraper-shaped traffic untouched while there is headroom" do
      wait = AnonLoadShed::SCRAPER_WAIT_THRESHOLD_SECONDS - 0.1
      expect(middleware.call(scraper_env(wait: wait))).to eq([200, {}, ['ok']])
    end

    # The whole point is that the reader behind the scraper keeps their budget.
    it "leaves the reader threshold where it was" do
      wait = AnonLoadShed::WAIT_THRESHOLD_SECONDS - 0.1
      expect(middleware.call(env(accept: real_accept, user_agent: chrome_ua, wait: wait)).first).to eq(200)
    end

    # Real Chrome sends the token, so it is never classified by the UA alone.
    it "does not shed real Chrome early" do
      real = env(wait: 3.0, accept: real_accept, user_agent: chrome_ua)
      expect(middleware.call(real)).to eq([200, {}, ['ok']])
    end

    # Firefox and Safari never send signed-exchange. Testing Accept alone would
    # classify every one of their users as a scraper, which is why the Chrome
    # claim is required too.
    it "does not shed browsers that never send the token" do
      firefox = env(wait: 3.0, accept: forged_accept, user_agent: firefox_ua)
      expect(middleware.call(firefox)).to eq([200, {}, ['ok']])
    end

    # Subresources carry a different Accept and are not navigations; a page's
    # images should not be judged apart from the page.
    it "does not classify subresource requests" do
      image = env(wait: 3.0, accept: 'image/avif,image/webp,*/*', user_agent: chrome_ua)
      expect(middleware.call(image)).to eq([200, {}, ['ok']])
    end

    it "passes through a bare env with no headers at all" do
      expect(middleware.call(env(wait: 3.0))).to eq([200, {}, ['ok']])
    end

    # A logged-in reader on a Chrome build that omits the token is a reader,
    # not a scraper, and the login checks still run after the shape check.
    it "never sheds a logged-in user early, whatever shape their request is" do
      expect(middleware.call(scraper_env(wait: 3.0, user_id: 1))).to eq([200, {}, ['ok']])
    end

    it "never sheds a remembered user early either" do
      expect(middleware.call(scraper_env(wait: 3.0, remembered: 7))).to eq([200, {}, ['ok']])
    end

    it "never sheds a scraper-shaped login request" do
      expect(middleware.call(scraper_env(wait: 3.0, path: '/login')).first).to eq(200)
    end
  end
end
