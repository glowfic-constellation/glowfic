require "spec_helper"

RSpec.describe Api::V1::TemplatesController do
  describe "GET index" do
    def create_search_templates
      firsttemplate = create(:template, name: 'baa')
      midtemplate = create(:template, name: 'aba')
      endtemplate = create(:template, name: 'aab')
      nottemplate = create(:template, name: 'aaa')
      Template.all.each do |template|
        create(:template, name: template.name.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_templates
      login
      get :index
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(8)
    end

    it "works logged out", show_in_doc: true do
      create_search_templates
      get :index, q: 'b'
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(2)
    end

    it "raises error on invalid page", show_in_doc: true do
      get :index, page: 'b'
      expect(response).to have_http_status(422)
    end

    it "raises error on invalid user", show_in_doc: true do
      get :index, user_id: 'b'
      expect(response).to have_http_status(422)
    end

    it "raises error on not found user", show_in_doc: true do
      get :index, user_id: '12'
      expect(response).to have_http_status(422)
    end

    it "finds only user's templates", show_in_doc: true do
      user = create(:user)
      notuser = create(:user)
      template = create(:template, user: user)
      nottemplate = create(:template, user: notuser)

      get :index, user_id: template.user_id
      expect(response.json['results'].count).to eq(1)
    end
  end
end
