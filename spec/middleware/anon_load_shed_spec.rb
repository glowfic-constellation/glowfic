RSpec.describe AnonLoadShed do
  let(:downstream) { ->(_env) { [200, {}, ['ok']] } }
  let(:middleware) { AnonLoadShed.new(downstream) }

  def env(wait: nil, user_id: nil, path: '/posts')
    {
      'rack.timeout.info' => wait && Struct.new(:wait).new(wait),
      'rack.session'      => { user_id: user_id },
      'PATH_INFO'         => path,
    }
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
end
