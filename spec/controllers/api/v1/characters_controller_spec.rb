require "spec_helper"

RSpec.describe Api::V1::CharactersController do
  describe "GET show" do
    it "requires valid character", :show_in_doc do
      get :show, id: -1
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Character could not be found.")
    end

    it "succeeds with valid character" do
      character = create(:character)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['name']).to eq(character.name)
    end

    it "succeeds for logged in users with valid character" do
      character = create(:character)
      login
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['name']).to eq(character.name)
    end

    it "has single gallery when present" do
      character = create(:character)
      character.galleries << create(:gallery, user: character.user)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(1)
    end

    it "has single gallery when icon present" do
      character = create(:character)
      character.default_icon = create(:icon, user: character.user)
      character.save
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(1)
    end

    it "has associations when present", :show_in_doc do
      character = create(:character)
      calias = create(:alias, character: character)
      character.galleries << create(:gallery, user: character.user, icon_count: 2)
      character.galleries << create(:gallery, user: character.user, icon_count: 1)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(2)
      expect(response.json['aliases'].size).to eq(1)
      expect(response.json['aliases'].first['id']).to eq(calias.id)
    end

    it "has galleries when icon_picker_grouping is false" do
      user = create(:user, icon_picker_grouping: false)
      character = create(:character, user: user)
      character.galleries << create(:gallery, user: user)
      character.galleries << create(:gallery, user: user)
      get :show, id: character.id
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(1)
    end

    context "with post_id" do
      it "requires valid post_id if given", :show_in_doc do
        character = create(:character)
        get :show, id: character.id, post_id: 0 # using -1 gets an error that it's not a number?
        expect(response).to have_http_status(422)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'].first['message']).to eq('Post could not be found.')
      end

      it "requires post be visible if post_id given" do
        character = create(:character)
        post = create(:post, privacy: Post::PRIVACY_PRIVATE)

        get :show, id: character.id, post_id: post.id
        expect(response).to have_http_status(422)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'].first['message']).to eq('You do not have permission to perform this action.')
      end

      it "has no active_alias when the post does not contain the character", :show_in_doc do
        character = create(:character)
        create(:alias, character: character)
        post = create(:post)

        get :show, id: character.id, post_id: post.id
        expect(response).to have_http_status(200)
        expect(response.json['active_alias']).to be_blank
      end

      it "sets active_alias from post" do
        character = create(:character)
        calias = create(:alias, character: character)
        post = create(:post, user: character.user, character: character, character_alias: calias)

        get :show, id: character.id, post_id: post.id
        expect(response).to have_http_status(200)
        expect(response.json['active_alias']['id']).to eq(calias.id)
      end

      it "has no active_alias if last reply with character had no alias" do
        character = create(:character)
        calias = create(:alias, character: character)
        post = create(:post, user: character.user, character: character, character_alias: calias)
        create(:reply, user: character.user, character: character, post: post)

        get :show, id: character.id, post_id: post.id
        expect(response).to have_http_status(200)
        expect(response.json['active_alias']).to be_blank
      end

      it "sets active_alias from last reply", :show_in_doc do
        character = create(:character)
        calias1 = create(:alias, character: character)
        calias2 = create(:alias, character: character)
        post = create(:post, user: character.user, character: character, character_alias: calias1)
        create(:reply, user: character.user, character: character, post: post, character_alias: calias2)

        get :show, id: character.id, post_id: post.id
        expect(response).to have_http_status(200)
        expect(response.json['active_alias']['id']).to eq(calias2.id)
      end
    end
  end

  describe "PUT update" do
    it "requires login", :show_in_doc do
      put :update, id: -1
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires valid character", :show_in_doc do
      login
      put :update, id: -1
      expect(response).to have_http_status(404)
      expect(response.json['errors'][0]['message']).to eq("Character could not be found.")
    end

    it "requires permission", :show_in_doc do
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
      expect(response.json['name']).to eq(character.name)
      expect(character.reload.default_icon_id).to be_nil
    end

    it "changes icon if valid", :show_in_doc do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      new_icon = create(:icon, user: icon.user)
      login_as(character.user)

      put :update, id: character.id, character: {default_icon_id: new_icon.id}

      expect(response.status).to eq(200)
      expect(response.json['name']).to eq(character.name)
      expect(character.reload.default_icon_id).to eq(new_icon.id)
    end

    it "handles validation failures", :show_in_doc do
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
