require "spec_helper"

RSpec.describe Api::V1::TagsController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      it "should support tag search", show_in_doc: in_doc do
        tag = create(:tag)
        get :index, q: tag.name, t: 'tag'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should suuport setting search", show_in_doc: in_doc do
        tag = create(:setting)
        get :index, q: tag.name, t: 'setting'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should support content warning search", show_in_doc: in_doc do
        tag = create(:content_warning)
        get :index, q: tag.name, t: 'warning'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(tag.as_json.stringify_keys)
      end

      it "should handle invalid input", show_in_doc: in_doc do
        get :index, t: 'b'
        expect(response).to have_http_status(422)
        expect(response.json).to have_key('errors')
        expect(response.json['errors'].first).to include("Invalid parameter 't'")
      end

      it "should require tag" do
      end
    end

    context "when logged in" do
      before(:each) { login }
      it_behaves_like "index.json", false
    end

    context "when logged out" do
      it_behaves_like "index.json", true
    end
  end
end
