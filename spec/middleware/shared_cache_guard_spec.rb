RSpec.describe SharedCacheGuard do
  def guard(headers)
    described_class.new(->(_env) { [200, headers, ['body']] })
  end

  def call(headers)
    guard(headers).call({})
  end

  it "withdraws sharing from a response that sets a cookie" do
    _status, headers, = call({ 'cache-control' => 'max-age=0, public, s-maxage=300', 'set-cookie' => '_glowfic=abc' })
    expect(headers['cache-control']).to eq('private, no-store')
  end

  it "leaves a shareable response alone when no cookie goes out" do
    _status, headers, = call({ 'cache-control' => 'max-age=0, public, s-maxage=300' })
    expect(headers['cache-control']).to eq('max-age=0, public, s-maxage=300')
  end

  it "leaves an ordinary private response alone" do
    _status, headers, = call({ 'cache-control' => 'max-age=0, private, must-revalidate', 'set-cookie' => '_glowfic=abc' })
    expect(headers['cache-control']).to eq('max-age=0, private, must-revalidate')
  end

  it "passes through a response with no cache-control at all" do
    status, headers, body = call({})
    expect([status, headers, body]).to eq([200, {}, ['body']])
  end

  it "reads capitalised header names too" do
    _status, headers, = call({ 'Cache-Control' => 'public, s-maxage=300', 'Set-Cookie' => '_glowfic=abc' })
    expect(headers['cache-control']).to eq('private, no-store')
  end

  it "does not leave the old capitalised header behind to contradict it" do
    _status, headers, = call({ 'Cache-Control' => 'public, s-maxage=300', 'Set-Cookie' => '_glowfic=abc' })
    expect(headers).not_to have_key('Cache-Control')
  end

  it "sits outside the middleware that writes Set-Cookie" do
    stack = Rails.application.middleware.map(&:klass)
    expect(stack.index(SharedCacheGuard)).to be < stack.index(ActionDispatch::Cookies)
  end
end
