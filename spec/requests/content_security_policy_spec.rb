RSpec.describe "Content-Security-Policy" do
  it "is report-only and nonces the inline gon script" do
    get "/login"
    expect(response).to have_http_status(200)
    expect(response.headers['Content-Security-Policy']).to be_nil
    policy = response.headers['Content-Security-Policy-Report-Only']
    expect(policy).to include("default-src 'self'", "object-src 'none'", "report-uri /csp_reports")
    nonce = policy[/script-src [^;]*'nonce-([^']+)'/, 1]
    expect(nonce).to be_present
    expect(response.body).to include("nonce=\"#{nonce}\"")
  end
end
