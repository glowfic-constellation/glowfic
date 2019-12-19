require "spec_helper"

RSpec.describe Api::V1::ContinuitiesController do
  describe "GET index" do
    def create_search_continuities
      create(:continuity, name: 'baa') # firstuser
      create(:continuity, name: 'aba') # miduser
      create(:continuity, name: 'aab') # enduser
      create(:continuity, name: 'aaa') # notuser
      Continuity.all.each do |continuity|
        create(:continuity, name: continuity.name.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_continuities
      login
      get :index
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(8)
    end

    it "works logged out", show_in_doc: true do
      create_search_continuities
      get :index, params: { q: 'b' }
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(2)
    end

    it "raises error on invalid page", show_in_doc: true do
      get :index, params: { page: 'b' }
      expect(response).to have_http_status(422)
    end
  end

  describe "GET show" do
    it "requires valid continuity", :show_in_doc do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Continuity could not be found.")
    end

    it "succeeds with valid continuity" do
      continuity = create(:continuity)
      section1 = create(:subcontinuity, continuity: continuity)
      section2 = create(:subcontinuity, continuity: continuity)
      get :show, params: { id: continuity.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(continuity.id)
      expect(response.json['subcontinuities'].size).to eq(2)
      expect(response.json['subcontinuities'][0]['id']).to eq(section1.id)
      expect(response.json['subcontinuities'][1]['id']).to eq(section2.id)
    end

    it "succeeds for logged in users with valid continuity" do
      login
      continuity = create(:continuity)
      section1 = create(:subcontinuity, continuity: continuity)
      section2 = create(:subcontinuity, continuity: continuity)
      get :show, params: { id: continuity.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(continuity.id)
      expect(response.json['subcontinuities'].size).to eq(2)
      expect(response.json['subcontinuities'][0]['id']).to eq(section1.id)
      expect(response.json['subcontinuities'][1]['id']).to eq(section2.id)
    end

    it "orders sections by section_order", :show_in_doc do
      continuity = create(:continuity)
      section1 = create(:subcontinuity, continuity: continuity)
      section2 = create(:subcontinuity, continuity: continuity)
      section1.section_order = 1
      section1.save!
      section2.section_order = 0
      section2.save!
      get :show, params: { id: continuity.id }
      expect(response).to have_http_status(200)
      expect(response.json['id']).to eq(continuity.id)
      expect(response.json['subcontinuities'].size).to eq(2)
      expect(response.json['subcontinuities'][0]['id']).to eq(section2.id)
      expect(response.json['subcontinuities'][0]['order']).to eq(0)
      expect(response.json['subcontinuities'][1]['id']).to eq(section1.id)
      expect(response.json['subcontinuities'][1]['order']).to eq(1)
    end
  end
end
