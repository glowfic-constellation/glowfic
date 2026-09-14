RSpec.describe "AnonLoadShed cookie handling" do
  # The unit spec stubs the cookie jar, so it proves the middleware's branching
  # but not that a real signed cookie is actually readable from where the
  # middleware sits in the stack. That is the part most likely to break: the
  # jar needs `action_dispatch.key_generator` and friends on the env, and if
  # they were missing the rescue in `permanent_user_id` would swallow it and
  # silently shed every remembered reader — exactly the bug being fixed, with
  # green unit tests. So build the cookie the way SessionsController does and
  # read it back through the middleware's own code path.
  before(:each) do
    stub_const('Rack::Timeout::ENV_INFO_KEY', 'rack-timeout.info') unless defined?(Rack::Timeout::ENV_INFO_KEY)
  end

  let(:downstream) { ->(_env) { [200, {}, ['ok']] } }
  let(:middleware) { AnonLoadShed.new(downstream) }
  let(:user) { create(:user) }

  # Log in for real with "remember me" so the signed cookie is produced by the
  # application rather than hand-rolled here, then keep only that cookie: a
  # returning reader whose browser dropped the session cookie sends exactly
  # this and nothing else.
  def remember_me_cookie
    post '/login', params: { username: user.username, password: 'knownpass', remember_me: true }
    raw = response.headers['Set-Cookie']
    raw = raw.join("\n") if raw.is_a?(Array)
    entry = raw.split("\n").find { |c| c.start_with?('user_id=') }
    expect(entry).to be_present, "expected login to set a permanent user_id cookie"
    entry.split(';').first
  end

  def env_with(cookie:, wait:)
    Rails.application.env_config.merge(
      Rack::MockRequest.env_for('/posts', 'HTTP_COOKIE' => cookie),
    ).merge(
      Rack::Timeout::ENV_INFO_KEY => Struct.new(:wait).new(wait),
      'rack.session'              => {},
    )
  end

  it "passes through a remembered reader carrying only the permanent cookie" do
    status, = middleware.call(env_with(cookie: remember_me_cookie, wait: 30.0))
    expect(status).to eq(200)
  end

  it "sheds an otherwise identical request whose cookie signature is tampered with" do
    tampered = remember_me_cookie.sub(/.$/) { |c| c == 'A' ? 'B' : 'A' }
    status, = middleware.call(env_with(cookie: tampered, wait: 30.0))
    expect(status).to eq(503)
  end
end
