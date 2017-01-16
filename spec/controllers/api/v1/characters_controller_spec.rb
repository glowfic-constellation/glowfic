require "spec_helper"

RSpec.describe Api::V1::CharactersController do
  describe "GET show" do
    it "requires valid character" do
      get :show, id: -1
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Character could not be found.")
    end

    it "succeeds with valid character" do
      character = create(:character)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['data']['name']).to eq(character.name)
    end

    it "succeeds for logged in users with valid character" do
      character = create(:character)
      login
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['data']['name']).to eq(character.name)
    end

    it "has single gallery when present" do
      character = create(:character)
      character.galleries << create(:gallery, user: character.user)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['data']['galleries'].size).to eq(1)
    end

    it "has single gallery when icon present" do
      character = create(:character)
      character.default_icon = create(:icon, user: character.user)
      character.save
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['data']['galleries'].size).to eq(1)
    end

    it "has galleries when present" do
      character = create(:character)
      character.galleries << create(:gallery, user: character.user, icon_count: 2)
      character.galleries << create(:gallery, user: character.user, icon_count: 1)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['data']['galleries'].size).to eq(2)
    end

    it "has galleries when icon_picker_grouping is false" do
      user = create(:user, icon_picker_grouping: false)
      character = create(:character, user: user)
      character.galleries << create(:gallery, user: user)
      character.galleries << create(:gallery, user: user)
      login_as(user)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['data']['galleries'].size).to eq(1)
    end
  end
end
