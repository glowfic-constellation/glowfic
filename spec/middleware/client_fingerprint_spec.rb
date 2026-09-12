RSpec.describe ClientFingerprint do
  let(:downstream) { ->(_env) { [200, {}, ['ok']] } }
  let(:middleware) { ClientFingerprint.new(downstream) }

  # Rack hands middleware an ordered hash and Ruby hashes preserve insertion
  # order, so the sequence headers are written here is the sequence the
  # ordered digest sees - the same thing Puma's parser produces from the wire.
  def env(headers={}, method: 'GET', protocol: 'HTTP/1.1')
    { 'REQUEST_METHOD' => method, 'SERVER_PROTOCOL' => protocol }.merge(headers)
  end

  # Four headers, so JA4H_a's count component is a stable "04" across examples
  # that do not deliberately add more.
  def chrome_headers
    {
      'HTTP_HOST'            => 'glowfic.com',
      'HTTP_USER_AGENT'      => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/145.0.0.0 Safari/537.36',
      'HTTP_ACCEPT'          => 'text/html,application/xhtml+xml',
      'HTTP_ACCEPT_LANGUAGE' => 'en-US,en;q=0.9',
    }
  end

  def attributes_for(request_env)
    captured = nil
    allow(NewRelic::Agent).to receive(:add_custom_attributes) { |attrs| captured = attrs }
    middleware.call(request_env)
    captured
  end

  it "passes the request through untouched" do
    expect(middleware.call(env(chrome_headers))).to eq([200, {}, ['ok']])
  end

  describe "JA4H_a" do
    it "encodes method, version, cookie and referer state, header count and language" do
      attrs = attributes_for(env(chrome_headers))
      expect(attrs['ja4h_a']).to eq('ge11nn04enus')
    end

    it "flags cookie and referer presence without counting them as headers" do
      attrs = attributes_for(env(chrome_headers.merge(
        'HTTP_COOKIE'  => '_glowfic_constellation_production=abc123',
        'HTTP_REFERER' => 'https://glowfic.com/boards',
      )))
      expect(attrs['ja4h_a']).to eq('ge11cr04enus')
    end

    it "reports all zeroes for a client that sends no Accept-Language" do
      attrs = attributes_for(env(chrome_headers.except('HTTP_ACCEPT_LANGUAGE')))
      expect(attrs['ja4h_a']).to eq('ge11nn030000')
    end

    it "encodes the request method" do
      attrs = attributes_for(env(chrome_headers, method: 'POST'))
      expect(attrs['ja4h_a']).to start_with('po11')
    end
  end

  describe "the header-name digests" do
    it "distinguishes clients that send the same headers in a different order" do
      forward = attributes_for(env(chrome_headers))
      reverse = attributes_for(env(chrome_headers.to_a.reverse.to_h))
      expect(forward['ja4h_b']).not_to eq(reverse['ja4h_b'])
    end

    it "still matches those clients on the order-insensitive digest" do
      forward = attributes_for(env(chrome_headers))
      reverse = attributes_for(env(chrome_headers.to_a.reverse.to_h))
      expect(forward['ja4h_b_sorted']).to eq(reverse['ja4h_b_sorted'])
    end

    it "separates clients that send a different set of headers" do
      spare = attributes_for(env(chrome_headers.except('HTTP_ACCEPT_LANGUAGE')))
      expect(spare['ja4h_b_sorted']).not_to eq(attributes_for(env(chrome_headers))['ja4h_b_sorted'])
    end

    it "leaves cookie, referer and authorization out, so the digest tracks the client not the request" do
      bare = attributes_for(env(chrome_headers))
      loaded = attributes_for(env(chrome_headers.merge(
        'HTTP_COOKIE'        => '_glowfic_constellation_production=abc123',
        'HTTP_REFERER'       => 'https://glowfic.com/boards',
        'HTTP_AUTHORIZATION' => 'Bearer sekrit',
      )))
      expect(loaded['ja4h_b']).to eq(bare['ja4h_b'])
    end

    it "ignores the headers Heroku's router injects between client and dyno" do
      bare = attributes_for(env(chrome_headers))
      proxied = attributes_for(env(chrome_headers.merge(
        'HTTP_X_FORWARDED_FOR'   => '203.0.113.7',
        'HTTP_X_FORWARDED_PROTO' => 'https',
        'HTTP_X_REQUEST_ID'      => 'deadbeef',
        'HTTP_CONNECTION'        => 'close',
      )))
      expect(proxied['ja4h_b']).to eq(bare['ja4h_b'])
    end
  end

  describe "Sec-* headers" do
    it "records what a real browser navigation sends" do
      attrs = attributes_for(env(chrome_headers.merge(
        'HTTP_SEC_FETCH_DEST'     => 'document',
        'HTTP_SEC_FETCH_MODE'     => 'navigate',
        'HTTP_SEC_FETCH_SITE'     => 'none',
        'HTTP_SEC_CH_UA_PLATFORM' => '"Windows"',
        'HTTP_SEC_CH_UA'          => '"Chromium";v="145"',
      )))
      expect(attrs).to include(
        'sec_fetch_dest'     => 'document',
        'sec_fetch_mode'     => 'navigate',
        'sec_fetch_site'     => 'none',
        'sec_ch_ua_platform' => '"Windows"',
        'has_sec_ch_ua'      => true,
      )
    end

    it "marks them absent rather than dropping them, since absence is the signal" do
      attrs = attributes_for(env(chrome_headers))
      expect(attrs).to include(
        'sec_fetch_dest' => '(absent)',
        'sec_fetch_mode' => '(absent)',
        'has_sec_ch_ua'  => false,
      )
    end
  end

  describe "sampled order logging" do
    it "logs the raw header order so the ordered digest can be validated against the wire" do
      stub_const('ClientFingerprint::LOG_SAMPLE_RATE', 1.0)
      expect(Rails.logger).to receive(:info).with(/\[client_fingerprint\].*order=host,user-agent,accept,accept-language/)
      middleware.call(env(chrome_headers))
    end

    it "stays quiet when sampling is disabled" do
      stub_const('ClientFingerprint::LOG_SAMPLE_RATE', 0.0)
      expect(Rails.logger).not_to receive(:info)
      middleware.call(env(chrome_headers))
    end
  end

  it "serves the request anyway when fingerprinting raises" do
    allow(NewRelic::Agent).to receive(:add_custom_attributes).and_raise(StandardError, 'boom')
    expect(Rails.logger).to receive(:warn).with(/ClientFingerprint failed: StandardError: boom/)
    expect(middleware.call(env(chrome_headers))).to eq([200, {}, ['ok']])
  end
end
