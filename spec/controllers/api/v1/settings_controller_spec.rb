RSpec.describe Api::V1::SettingsController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      it "should support setting search", show_in_doc: in_doc do
        setting = create(:setting)
        get :index, params: { q: setting.name }
        expect(response).to have_http_status(200)
        expect(response.parsed_body).to have_key('results')
        expect(response.parsed_body['results']).to contain_exactly(setting.as_json.stringify_keys)
      end

      it "should handle invalid input", show_in_doc: in_doc do
        get :index, params: { t: 'b' }
        expect(response).to have_http_status(422)
        expect(response.parsed_body).to have_key('errors')
        expect(response.parsed_body['errors'].first['message']).to include("Invalid parameter 't'")
      end
    end

    context "when logged in" do
      before(:each) { api_login }

      it_behaves_like "index.json", false
    end

    context "when logged out" do
      it_behaves_like "index.json", true
    end
  end

  describe "GET show" do
    it "should support getting setting tags" do
      setting = create(:setting)
      get :show, params: { id: setting.id }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['id']).to eq(setting.id)
    end

    it "should handle invalid tag", :show_in_doc do
      get :show, params: { id: 99 }
      expect(response).to have_http_status(404)
      expect(response.parsed_body).to have_key('errors')
      expect(response.parsed_body['errors'][0]['message']).to eq("Setting could not be found")
    end
  end
end
