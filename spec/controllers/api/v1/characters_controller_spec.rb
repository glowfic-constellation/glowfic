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

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires valid character" do
      login
      put :update, id: -1
      expect(response).to have_http_status(404)
      expect(response.json['errors'][0]['message']).to eq("Character could not be found.")
    end

    it "requires permission" do
      character = create(:character)
      login
      put :update, id: character.id
      expect(response).to have_http_status(403)
      expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "does not change icon if invalid icon provided" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      login_as(character.user)
      put :update, id: character.id, character: {default_icon_id: -1}
      expect(response).to have_http_status(422)
      expect(response.json['errors'][0]['message']).to eq("Default icon could not be found")
      expect(character.reload.default_icon_id).to eq(icon.id)
    end

    it "does not change icon if someone else's icon provided" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      login_as(character.user)
      put :update, id: character.id, character: {default_icon_id: create(:icon).id}
      expect(response).to have_http_status(422)
      expect(response.json['errors'][0]['message']).to eq("Default icon must be yours")
      expect(character.reload.default_icon_id).to eq(icon.id)
    end

    it "removes icon successfully with empty icon_id" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      login_as(character.user)
      put :update, id: character.id, character: {default_icon_id: ''}
      expect(response.status).to eq(200)
      expect(response.json['data']['name']).to eq(character.name)
      expect(character.reload.default_icon_id).to be_nil
    end

    it "changes icon if valid" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      new_icon = create(:icon, user: icon.user)
      login_as(character.user)

      put :update, id: character.id, character: {default_icon_id: new_icon.id}

      expect(response.status).to eq(200)
      expect(response.json['data']['name']).to eq(character.name)
      expect(character.reload.default_icon_id).to eq(new_icon.id)
    end

    it "handles validation failures" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      new_icon = create(:icon, user: icon.user)
      login_as(character.user)

      put :update, id: character.id, character: {default_icon_id: new_icon.id, name: '', user_id: nil}

      expect(response.status).to eq(422)
      expect(response.json['errors'][0]['message']).to eq("Name can't be blank")
      expect(response.json['errors'][1]['message']).to eq("User can't be blank")
      expect(character.reload.default_icon_id).to eq(icon.id)
    end
  end
end
