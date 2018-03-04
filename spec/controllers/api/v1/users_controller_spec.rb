require "spec_helper"

RSpec.describe Api::V1::UsersController do
  describe "GET index" do
    def create_search_users
      create(:user, username: 'baa') # firstuser
      create(:user, username: 'aba') # miduser
      create(:user, username: 'aab') # enduser
      create(:user, username: 'aaa') # notuser
      User.all.each do |user|
        create(:user, username: user.username.upcase + 'c')
      end
    end

    it "works logged in" do
      create_search_users
      login
      get :index
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(9)
    end

    it "works logged out", show_in_doc: true do
      create_search_users
      get :index, params: { q: 'b' }
      expect(response).to have_http_status(200)
      expect(response.json['results'].count).to eq(2)
    end

    it "raises error on invalid page", show_in_doc: true do
      get :index, params: { page: 'b' }
      expect(response).to have_http_status(422)
    end
  end
end
