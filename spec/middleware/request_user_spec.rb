RSpec.describe RequestUser do
  # `remembered` is the user id the signed `user_id` cookie verifies to, or nil
  # where the cookie is absent, forged or otherwise unverifiable. Omitting it
  # leaves no jar on the env at all, which is what a bare Rack env looks like.
  def env(user_id: nil, remembered: :no_jar)
    base = { 'rack.session' => { user_id: user_id } }
    return base if remembered == :no_jar
    jar = instance_double(ActionDispatch::Cookies::CookieJar, signed: { user_id: remembered })
    base.merge('action_dispatch.cookies' => jar)
  end

  it "reads the user from the session" do
    expect(RequestUser.id(env(user_id: 3))).to eq(3)
  end

  it "prefers the session over the permanent cookie" do
    expect(RequestUser.id(env(user_id: 3, remembered: 7))).to eq(3)
  end

  it "falls back to a verified permanent cookie when the session has no user" do
    expect(RequestUser.id(env(remembered: 7))).to eq(7)
  end

  it "is nil when neither the session nor the cookie names a user" do
    expect(RequestUser.id(env(remembered: nil))).to be_nil
  end

  it "is nil without a session at all" do
    expect(RequestUser.id({})).to be_nil
  end

  it "treats a jar it cannot read as anonymous rather than raising" do
    expect(RequestUser.id(env.merge('action_dispatch.cookies' => Object.new))).to be_nil
  end

  # The stubbed jar above proves the branching, not that a real signed cookie
  # is readable from a Rack env before any controller runs. Build the cookie the
  # way SessionsController does and read it back.
  describe "with a real remember-me cookie", type: :request do
    let(:user) { create(:user) }

    def remember_me_cookie
      post '/login', params: { username: user.username, password: 'knownpass', remember_me: '1' }
      raw = response.headers['Set-Cookie']
      raw = raw.join("\n") if raw.is_a?(Array)
      entry = raw.split("\n").find { |c| c.start_with?('user_id=') }
      expect(entry).to be_present, "expected login to set a permanent user_id cookie"
      entry.split(';').first
    end

    def env_with(cookie)
      Rails.application.env_config.merge(Rack::MockRequest.env_for('/posts', 'HTTP_COOKIE' => cookie)).merge('rack.session' => {})
    end

    it "identifies the reader from the cookie alone" do
      expect(RequestUser.id(env_with(remember_me_cookie))).to eq(user.id)
    end

    it "ignores a cookie whose signature is tampered with" do
      tampered = remember_me_cookie.sub(/.$/) { |c| c == 'A' ? 'B' : 'A' }
      expect(RequestUser.id(env_with(tampered))).to be_nil
    end
  end
end
