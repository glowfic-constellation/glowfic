RSpec.describe Api::V1::TemplatesController do
  describe "GET index" do
    def create_search_templates
      create(:template, name: 'baa') # firsttemplate
      create(:template, name: 'aba') # midtemplate
      create(:template, name: 'aab') # endtemplate
      create(:template, name: 'aaa') # nottemplate
      Template.find_each do |template|
        create(:template, name: template.name.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_templates
      api_login
      get :index
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].count).to eq(8)
      expect(response.parsed_body['results'].first['dropdown']).not_to be_present
    end

    it "works logged out", :show_in_doc do
      create_search_templates
      get :index, params: { q: 'b' }
      expect(response).to have_http_status(200)
      expect(response.parsed_body['results'].count).to eq(2)
      expect(response.parsed_body['results'].first['dropdown']).not_to be_present
    end

    it "raises error on invalid page", :show_in_doc do
      get :index, params: { page: 'b' }
      expect(response).to have_http_status(422)
    end

    it "raises error on invalid user", :show_in_doc do
      get :index, params: { user_id: 'b' }
      expect(response).to have_http_status(422)
    end

    it "raises error on not found user", :show_in_doc do
      get :index, params: { user_id: '12' }
      expect(response).to have_http_status(422)
    end

    it "finds only user's templates", :show_in_doc do
      user = create(:user)
      notuser = create(:user)
      template = create(:template, user: user)
      create(:template, user: notuser) # nottemplate

      get :index, params: { user_id: template.user_id }
      expect(response.parsed_body['results'].count).to eq(1)
    end

    it "includes dropdown text when prompted", :show_in_doc do
      create(:template, name: 'Template Dropdown')
      get :index, params: { dropdown: 'true' }
      expect(response.parsed_body['results'].count).to eq(1)
      expect(response.parsed_body['results'].first['dropdown']).to be_present
    end
  end
end
