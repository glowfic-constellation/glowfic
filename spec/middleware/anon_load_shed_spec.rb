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
  # Long enough to shed a scraper-shaped request, not long enough to shed a reader.
  let(:between_thresholds) { (AnonLoadShed::SCRAPER_WAIT_THRESHOLD_SECONDS + AnonLoadShed::WAIT_THRESHOLD_SECONDS) / 2 }

  # Headers as the two populations actually send them. Real Chrome announces
  # signed-exchange on navigations; the scrape's forged Chrome UAs do not.
  let(:chrome_ua) { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36' }
  let(:firefox_ua) { 'Mozilla/5.0 (X11; Linux x86_64; rv:129.0) Gecko/20100101 Firefox/129.0' }
  let(:real_accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9,application/signed-exchange;v=b3;q=0.7' }
  # What real Chrome 145 sends alongside that Accept on a navigation.
  let(:real_sec_headers) do
    {
      'HTTP_SEC_FETCH_MODE' => 'navigate',
      'HTTP_SEC_CH_UA'      => '"Chromium";v="145", "Not:A-Brand";v="24", "Google Chrome";v="145"',
    }
  end
  let(:forged_accept) { 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' }

  # `remembered` is the user id the signed `user_id` cookie verifies to, or nil
  # where the cookie is absent, forged or otherwise unverifiable — the jar
  # returns nil for all three, so they are one case from here. Omitting it
  # leaves no jar on the env at all, which is what a bare Rack env looks like.
  def env(wait: nil, user_id: nil, path: '/posts', remembered: :no_jar, accept: nil, user_agent: nil, headers: {})
    base = headers.merge({
      Rack::Timeout::ENV_INFO_KEY => wait && Struct.new(:wait).new(wait),
      'rack.session'              => { user_id: user_id },
      'PATH_INFO'                 => path,
      'HTTP_ACCEPT'               => accept,
      'HTTP_USER_AGENT'           => user_agent,
    })
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
    expect(middleware.call(env(wait: between_thresholds))).to eq([200, {}, ['ok']])
  end

  it "passes through logged-in users even when the wait is large" do
    expect(middleware.call(env(wait: 30.0, user_id: 1))).to eq([200, {}, ['ok']])
  end

  it "counts a shed request by reason instead of recording a transaction" do
    AnonLoadShed.flush_shed_counts
    expect(NewRelic::Agent).to receive(:ignore_transaction).exactly(3).times
    middleware.call(env(wait: 10.0))
    middleware.call(env(wait: 10.0))
    middleware.call(scraper_env(wait: between_thresholds))

    expect(NewRelic::Agent).to receive(:increment_metric).with('Custom/AnonLoadShed/reader', 2)
    expect(NewRelic::Agent).to receive(:increment_metric).with('Custom/AnonLoadShed/no_sxg', 1)
    AnonLoadShed.flush_shed_counts
  end

  it "leaves a served request's transaction alone" do
    expect(NewRelic::Agent).not_to receive(:ignore_transaction)
    middleware.call(env(wait: between_thresholds))
  end

  it "sheds anonymous users whose request waited longer than the threshold" do
    status, headers, body = middleware.call(env(wait: 10.0))
    expect(status).to eq(503)
    expect(headers).to include('Retry-After' => '30')
    expect(body.first).to match(/busy/i)
  end

  it "sheds scraper-shaped requests after 0.3 seconds by default" do
    expect(AnonLoadShed::SCRAPER_WAIT_THRESHOLD_SECONDS).to eq(0.3)
  end

  it "sheds anonymous readers after two seconds by default" do
    expect(AnonLoadShed::WAIT_THRESHOLD_SECONDS).to eq(2.0)
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
    # These examples are about the browser-header signals alone.
    before(:each) { stub_const('AnonLoadShed::NO_COOKIE_TEST', false) }

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
      expect(middleware.call(env(accept: real_accept, user_agent: chrome_ua, wait: wait, headers: real_sec_headers)).first).to eq(200)
    end

    # Real Chrome sends the token, so it is never classified by the UA alone.
    it "does not shed real Chrome early" do
      real = env(wait: between_thresholds, accept: real_accept, user_agent: chrome_ua, headers: real_sec_headers)
      expect(middleware.call(real)).to eq([200, {}, ['ok']])
    end

    # Firefox and Safari never send signed-exchange. Testing Accept alone would
    # classify every one of their users as a scraper, which is why the Chrome
    # claim is required too.
    it "does not shed browsers that never send the token" do
      firefox = env(wait: between_thresholds, accept: forged_accept, user_agent: firefox_ua)
      expect(middleware.call(firefox)).to eq([200, {}, ['ok']])
    end

    # Subresources carry a different Accept and are not navigations; a page's
    # images should not be judged apart from the page.
    it "does not classify subresource requests" do
      image = env(wait: between_thresholds, accept: 'image/avif,image/webp,*/*', user_agent: chrome_ua)
      expect(middleware.call(image)).to eq([200, {}, ['ok']])
    end

    it "passes through a bare env with no headers at all" do
      expect(middleware.call(env(wait: between_thresholds))).to eq([200, {}, ['ok']])
    end

    # A logged-in reader on a Chrome build that omits the token is a reader,
    # not a scraper, and the login checks still run after the shape check.
    it "never sheds a logged-in user early, whatever shape their request is" do
      expect(middleware.call(scraper_env(wait: between_thresholds, user_id: 1))).to eq([200, {}, ['ok']])
    end

    it "never sheds a remembered user early either" do
      expect(middleware.call(scraper_env(wait: between_thresholds, remembered: 7))).to eq([200, {}, ['ok']])
    end

    it "never sheds a scraper-shaped login request" do
      expect(middleware.call(scraper_env(wait: between_thresholds, path: '/login')).first).to eq(200)
    end
  end

  describe "classifying a scraper that copies Chrome's Accept" do
    # These examples are about the browser-header signals alone.
    before(:each) { stub_const('AnonLoadShed::NO_COOKIE_TEST', false) }

    def copied(headers={}, user_agent: chrome_ua)
      { 'HTTP_ACCEPT' => real_accept, 'HTTP_USER_AGENT' => user_agent }.merge(real_sec_headers).merge(headers)
    end

    def shed_early?(headers)
      env_hash = env(wait: between_thresholds).merge(headers)
      middleware.call(env_hash).first == 503
    end

    it "passes a full, consistent Chrome header set" do
      expect(AnonLoadShed.scraper_signal(copied)).to be_nil
    end

    it "flags a request without Fetch Metadata" do
      expect(AnonLoadShed.scraper_signal(copied({ 'HTTP_SEC_FETCH_MODE' => nil }))).to eq('no_sec_fetch')
    end

    it "flags a request without the Sec-CH-UA client hint" do
      expect(AnonLoadShed.scraper_signal(copied({ 'HTTP_SEC_CH_UA' => nil }))).to eq('no_ch_ua')
    end

    it "flags a client hint that names another Chromium version than the UA" do
      rotated = chrome_ua.sub('Chrome/145', 'Chrome/131')
      expect(AnonLoadShed.scraper_signal(copied(user_agent: rotated))).to eq('ch_ua_mismatch')
    end

    it "passes another Chromium browser with a matching brand" do
      edge = copied(
        { 'HTTP_SEC_CH_UA' => '"Microsoft Edge";v="145", "Chromium";v="145", "Not)A;Brand";v="8"' },
        user_agent: "#{chrome_ua} Edg/145.0.0.0",
      )
      expect(AnonLoadShed.scraper_signal(edge)).to be_nil
    end

    it "passes GREASE brand lists in any order" do
      [
        '"Not_A Brand";v="99", "Google Chrome";v="145", "Chromium";v="145"',
        '"Google Chrome";v="145", "Not/A)Brand";v="8", "Chromium";v="145"',
        '"Chromium";v="145", "Google Chrome";v="145", "?Not:A_Brand";v="24"',
      ].each do |client_hint|
        expect(AnonLoadShed.scraper_signal(copied({ 'HTTP_SEC_CH_UA' => client_hint }))).to be_nil
      end
    end

    it "holds Android WebView to the Fetch Metadata check only" do
      webview_ua = 'Mozilla/5.0 (Linux; Android 14; Pixel 8; wv) AppleWebKit/537.36 (KHTML, like Gecko) ' \
                   'Version/4.0 Chrome/145.0.0.0 Mobile Safari/537.36'
      webview = copied({ 'HTTP_SEC_CH_UA' => nil }, user_agent: webview_ua)
      expect(AnonLoadShed.scraper_signal(webview)).to be_nil
    end

    it "sheds the copied-Accept scraper at the scraper threshold" do
      expect(shed_early?(copied({ 'HTTP_SEC_FETCH_MODE' => nil }))).to be(true)
      expect(shed_early?(copied)).to be(false)
    end

    it "falls back to the signed-exchange test alone when switched off" do
      stub_const('AnonLoadShed::SEC_FETCH_TEST', false)
      expect(AnonLoadShed.scraper_signal(copied({ 'HTTP_SEC_FETCH_MODE' => nil }))).to be_nil
      expect(AnonLoadShed.scraper_signal(copied({ 'HTTP_ACCEPT' => forged_accept }))).to eq('no_sxg')
    end
  end

  describe "classifying a client with no cookie" do
    def page(wait:, headers: {}, user_agent: chrome_ua)
      env(wait: wait, accept: real_accept, user_agent: user_agent, headers: real_sec_headers.merge(headers)).merge('REQUEST_METHOD' => 'GET')
    end

    it "sheds a full Chrome header set with no cookie at the scraper threshold" do
      status, = middleware.call(page(wait: between_thresholds))
      expect(status).to eq(503)
      expect(AnonLoadShed.scraper_signal(page(wait: 0))).to eq('no_cookie')
    end

    it "applies to browsers that are not Chrome as well" do
      status, = middleware.call(page(wait: between_thresholds, user_agent: firefox_ua))
      expect(status).to eq(503)
    end

    it "gives a returning reader with a cookie the reader threshold" do
      returning = page(wait: between_thresholds, headers: { 'HTTP_COOKIE' => '_glowfic_constellation_production=abc' })
      expect(middleware.call(returning)).to eq([200, {}, ['ok']])
    end

    it "does not count a first visit from a link on another site" do
      linked = page(wait: between_thresholds, headers: { 'HTTP_SEC_FETCH_SITE' => 'cross-site' })
      expect(middleware.call(linked)).to eq([200, {}, ['ok']])
    end

    it "catches a page load that accepts anything, as most of the scrape does" do
      any = env(wait: 0, accept: '*/*', user_agent: chrome_ua).merge('REQUEST_METHOD' => 'GET')
      expect(AnonLoadShed.scraper_signal(any)).to eq('no_cookie')
    end

    it "leaves the API alone, whose clients send no cookie" do
      api = env(wait: 0, accept: '*/*', path: '/api/v1/posts').merge('REQUEST_METHOD' => 'GET')
      expect(AnonLoadShed.scraper_signal(api)).to be_nil
    end

    it "leaves requests that are not GETs alone" do
      post = env(wait: 0, accept: real_accept).merge('REQUEST_METHOD' => 'POST')
      expect(AnonLoadShed.scraper_signal(post)).to be_nil
    end

    it "can be switched off" do
      stub_const('AnonLoadShed::NO_COOKIE_TEST', false)
      expect(middleware.call(page(wait: between_thresholds))).to eq([200, {}, ['ok']])
    end
  end

  describe "a safelisted address" do
    around(:each) do |example|
      was = $safe_ips
      $safe_ips = ['45.33.77.79']
      example.run
      $safe_ips = was
    end

    it "is never shed, because it fetches for many readers" do
      safe = env(wait: 30.0).merge('REMOTE_ADDR' => '45.33.77.79')
      expect(middleware.call(safe)).to eq([200, {}, ['ok']])
    end

    it "does not protect other addresses" do
      other = env(wait: 30.0).merge('REMOTE_ADDR' => '203.0.113.9')
      expect(middleware.call(other).first).to eq(503)
    end
  end
end
