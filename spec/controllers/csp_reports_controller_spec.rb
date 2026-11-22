RSpec.describe CspReportsController do
  describe "POST create" do
    it "logs a short summary without the query string" do
      report = { 'csp-report' => { 'violated-directive' => 'script-src', 'blocked-uri' => 'https://evil.example/x.js?token=abc', 'document-uri' => 'https://glowfic.test/posts/1?secret=1' } }
      logged = nil
      allow(Rails.logger).to receive(:warn) { |line| logged = line }
      post :create, body: report.to_json, as: :json
      expect(response).to have_http_status(204)
      expect(logged).to include('CSP violation', 'script-src', 'https://evil.example/x.js"')
      expect(logged).not_to include('token')
      expect(logged).not_to include('secret')
    end

    it "includes the script sample of a blocked inline handler" do
      report = { 'csp-report' => { 'violated-directive' => 'script-src-attr', 'blocked-uri' => 'inline', 'script-sample' => 'this.form.submit()' } }
      logged = nil
      allow(Rails.logger).to receive(:warn) { |line| logged = line }
      post :create, body: report.to_json, as: :json
      expect(logged).to include('script-sample="this.form.submit()"')
    end

    it "rejects bodies that are not JSON" do
      post :create, body: 'nope'
      expect(response).to have_http_status(400)
    end

    it "ignores reports of the wrong shape" do
      post :create, body: '{"csp-report": []}', as: :json
      expect(response).to have_http_status(204)
    end
  end
end
