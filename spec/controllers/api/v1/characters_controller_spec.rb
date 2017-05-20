require "spec_helper"

RSpec.describe Api::V1::CharactersController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      it "should support no search", show_in_doc: in_doc do
        char = create(:character)
        get :index
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json.stringify_keys)
      end

      it "should support search", show_in_doc: in_doc do
        char = create(:character, name: 'search')
        char2 = create(:character, name: 'no')
        get :index, q: 'se'
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json.stringify_keys)
      end

      it "requires valid post id if provided", show_in_doc: in_doc do
        char = create(:character)
        get :index, post_id: -1
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'][0]['message']).to eq("Post could not be found.")
      end

      it "requires post with permission", show_in_doc: in_doc do
        post = create(:post, privacy: Post::PRIVACY_PRIVATE, with_character: true)
        get :index, post_id: post.id
        expect(response).to have_http_status(:forbidden)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
      end

      it "filters by post", show_in_doc: in_doc do
        char = create(:character)
        char2 = create(:character)
        post = create(:post, character: char, user: char.user)
        get :index, post_id: post.id
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json.stringify_keys)
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

    it "requires post to exist when provided a post_id", :show_in_doc do
      character = create(:character)
      get :show, id: character.id, post_id: 0
      expect(response).to have_http_status(422)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires post to have permission when provided a post_id", :show_in_doc do
      post = create(:post, privacy: Post::PRIVACY_PRIVATE, with_character: true)
      get :show, id: post.character_id, post_id: post.id
      expect(response).to have_http_status(:forbidden)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "includes alias_id_for_post field when given post_id" do
      character = create(:character)
      post = create(:post, user: character.user)
      get :show, id: character.id, post_id: post.id
      expect(response).to have_http_status(200)
      expect(response.json).to have_key('alias_id_for_post')
      expect(response.json['alias_id_for_post']).to be_nil
    end

    it "sets correct alias_id_for_post when given post_id with recently used alias in post", :show_in_doc do
      calias = create(:alias)
      character = calias.character
      post = create(:post, user: character.user, character: character, character_alias_id: calias.id)
      get :show, id: character.id, post_id: post.id
      expect(response).to have_http_status(200)
      expect(response.json).to have_key('alias_id_for_post')
      expect(response.json['alias_id_for_post']).to eq(calias.id)
    end

    it "sets correct alias_id_for_post when given post_id with recently used alias in post" do
      calias = create(:alias)
      character = calias.character
      post = create(:post, user: character.user, character: character)
      reply = create(:reply, post: post, user: character.user, character: character, character_alias_id: calias.id)
      get :show, id: character.id, post_id: post.id
      expect(response).to have_http_status(200)
      expect(response.json).to have_key('alias_id_for_post')
      expect(response.json['alias_id_for_post']).to eq(calias.id)
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

    it "handles validation failures and invalid params", :show_in_doc do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      new_icon = create(:icon, user: icon.user)
      login_as(character.user)

      put :update, id: character.id, character: {default_icon_id: new_icon.id, name: '', user_id: nil}

      expect(response.status).to eq(422)
      expect(response.json['errors'][0]['message']).to eq("Name can't be blank")
      expect(character.reload.default_icon_id).to eq(icon.id)
      expect(character.reload.user_id).to eq(icon.user_id)
    end
  end
end
