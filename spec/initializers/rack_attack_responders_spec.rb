RSpec.describe RackAttackResponders do
  # rack-attack is a production-only gem, and `Rack::Attack::Request` is an
  # empty subclass of `Rack::Request`. The responders only ever call `env`,
  # `ip` and `path`, all of which come from `Rack::Request`, so fall back to it
  # where the gem isn't bundled. Where it IS present the real class is used,
  # guarding against that relationship drifting.
  def request_class
    defined?(Rack::Attack::Request) ? Rack::Attack::Request : Rack::Request
  end

  # rack-attack hands the responder a request and reads what it needs out of
  # the Rack env, so a bare env is the whole contract.
  def request(path: '/posts', client_ip: '203.0.113.1', matched: nil, limit: 25, period: 300, epoch_time: 1_757_000_000)
    env = {
      'PATH_INFO'              => path,
      'REMOTE_ADDR'            => client_ip,
      'rack.attack.matched'    => matched,
      'rack.attack.match_data' => { limit: limit, period: period, epoch_time: epoch_time },
    }
    request_class.new(env)
  end

  before(:each) { $safe_ips = [] }

  # Retry-After is the one header a client of any kind acts on, and it is the
  # header rack-attack quietly stops sending as soon as a custom responder is
  # assigned. Every 429 has to carry it.
  describe "throttled" do
    it "tells the client how long to wait" do
      _status, headers, _body = described_class::THROTTLED.call(request)
      expect(headers['retry-after']).to be_present
    end

    it "answers 429 rather than a code that reads as permanent" do
      status, = described_class::THROTTLED.call(request)
      expect(status).to eq(429)
    end

    # The wait is the remainder of the current throttle window, so a client
    # that obeys it returns exactly when its quota resets rather than sooner.
    # 1_757_000_220 sits 120s into a 300s window, leaving 180s to wait.
    it "waits out the rest of the window, not a fixed guess" do
      _status, headers, = described_class::THROTTLED.call(request(period: 300, epoch_time: 1_757_000_220))
      expect(headers['retry-after']).to eq('180')
    end

    it "sends Retry-After to anonymous clients, who are the ones being throttled" do
      _status, headers, = described_class::THROTTLED.call(request(client_ip: '198.51.100.9'))
      expect(headers['retry-after']).to be_present
      expect(headers).not_to have_key('ratelimit-limit')
    end

    # RateLimit-* describes a quota, which only means something to a caller
    # that knows it has one.
    it "adds quota headers for safelisted callers" do
      $safe_ips = ['203.0.113.1']
      _status, headers, = described_class::THROTTLED.call(request(client_ip: '203.0.113.1'))
      expect(headers).to include('ratelimit-limit' => '25', 'ratelimit-remaining' => '0')
    end

    it "adds quota headers for the documented API" do
      _status, headers, = described_class::THROTTLED.call(request(path: '/api/v1/characters'))
      expect(headers['ratelimit-limit']).to eq('25')
    end

    it "resets the quota when the wait expires" do
      _status, headers, = described_class::THROTTLED.call(request(path: '/api/v1/characters', period: 300, epoch_time: 1_757_000_220))
      expect(headers['ratelimit-reset'].to_i - 1_757_000_220).to eq(180)
    end
  end

  # A ban earned by request rate is temporary. Answering it with 403 tells a
  # crawler the URL is gone for good, which is both wrong and, as ClaudeBot's
  # 625,122 unbacked-off 403s showed, useless at slowing anything down.
  describe "blocklisted" do
    it "answers a rate-earned ban with 429 and a wait" do
      status, headers, _body = described_class::BLOCKLISTED.call(request(matched: described_class::ALLOW2BAN_NAME))
      expect(status).to eq(429)
      expect(headers['retry-after']).to eq(described_class::SHORT_BAN.to_i.to_s)
    end

    # `blocklist_ip` builds an anonymous blocklist, so a manually banned IP
    # arrives with no matched name. That one is a deliberate denial, and 403
    # states it accurately.
    it "still answers the manual bad-IP list with 403" do
      status, headers, _body = described_class::BLOCKLISTED.call(request(matched: nil))
      expect(status).to eq(403)
      expect(headers).not_to have_key('retry-after')
    end

    it "does not treat some other named blocklist as a rate ban" do
      status, = described_class::BLOCKLISTED.call(request(matched: 'something else'))
      expect(status).to eq(403)
    end

    # The advertised wait has to track the ban actually applied, or the client
    # is told to come back while still banned and simply burns the request.
    it "advertises a wait no longer than the ban it describes" do
      expect(described_class::SHORT_BAN).to be <= described_class::LONG_BAN
    end
  end

  # Rack 3 specifies lowercase header names, and the middleware wrapping these
  # responses looks them up that way.
  it "names every header the way Rack 3 and the surrounding middleware read them" do
    $safe_ips = ['203.0.113.1']
    responses = [
      described_class::THROTTLED.call(request(client_ip: '203.0.113.1')),
      described_class::THROTTLED.call(request),
      described_class::BLOCKLISTED.call(request(matched: described_class::ALLOW2BAN_NAME)),
      described_class::BLOCKLISTED.call(request),
    ]
    responses.each do |_status, headers, _body|
      expect(headers.keys).to all(satisfy { |key| key == key.downcase })
    end
  end
end
