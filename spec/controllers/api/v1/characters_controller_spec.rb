require "spec_helper"
require "support/shared/api_shared_examples"

RSpec.describe Api::V1::CharactersController do
  describe "GET index" do
    shared_examples_for "index.json" do |in_doc|
      let!(:char) { create(:character, name: 'a', nickname: 'b', screenname: 'c') }

      it "should support no search", show_in_doc: in_doc do
        get :index
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "should support search" do
        char.update!(name: 'search')
        create(:character, name: 'no')
        get :index, params: { q: 'se' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "requires valid post id if provided", show_in_doc: in_doc do
        get :index, params: { post_id: -1 }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'][0]['message']).to eq("Post could not be found.")
      end

      it "requires valid template id if provided", show_in_doc: in_doc do
        get :index, params: { template_id: 999 }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'][0]['message']).to eq("Template could not be found.")
      end

      it "requires valid user id if provided", show_in_doc: in_doc do
        get :index, params: { user_id: char.user_id + 1 }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'][0]['message']).to eq("User could not be found.")
      end

      it "requires valid includes if provided", show_in_doc: in_doc do
        get :index, params: { includes: ['invalid'] }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.json['errors'].size).to eq(1)
        expected = "Invalid parameter 'includes' value ['invalid']: Must be an array of ['default_icon', 'aliases', 'nickname']"
        expect(response.json['errors'][0]['message']).to eq(expected)
      end

      it "requires post with permission", show_in_doc: in_doc do
        post = create(:post, privacy: Concealable::PRIVATE, character: char, user: char.user)
        get :index, params: { post_id: post.id }
        expect(response).to have_http_status(:forbidden)
        expect(response.json['errors'].size).to eq(1)
        expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
      end

      it "filters by post" do
        create(:character)
        post = create(:post, character: char, user: char.user)
        get :index, params: { post_id: post.id }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "filters by template" do
        create(:character)
        char.update!(template: create(:template, user: char.user))
        get :index, params: { template_id: char.template_id }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "filters by templateless" do
        create(:template_character)
        get :index, params: { template_id: '0' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "filters by user id" do
        char2 = create(:character)
        login_as(char2.user)
        get :index, params: { user_id: char.user_id }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "matches lowercase" do
        char.update!(name: 'Upcase')
        get :index, params: { q: 'upcase' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "matches uppercase" do
        char.update!(name: 'downcase')
        get :index, params: { q: 'DOWNcase' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "matches nickname" do
        get :index, params: { q: 'b' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "matches screenname" do
        get :index, params: { q: 'c' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
      end

      it "matches midword" do
        char.update!(name: 'abcdefg')
        get :index, params: { q: 'cde' }
        expect(response).to have_http_status(200)
        expect(response.json).to have_key('results')
        expect(response.json['results']).to contain_exactly(char.as_json(include: [:selector_name]).stringify_keys)
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
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user) }
    let(:calias) { create(:alias, character: character) }
    let(:gallery) { create(:gallery, user: user) }

    it "requires valid character", :show_in_doc do
      get :show, params: { id: -1 }
      expect(response).to have_http_status(404)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Character could not be found.")
    end

    it "succeeds with valid character" do
      get :show, params: { id: character.id }
      expect(response).to have_http_status(200)
      expect(response.json['name']).to eq(character.name)
    end

    it "succeeds for logged in users with valid character" do
      login
      get :show, params: { id: character.id }
      expect(response).to have_http_status(200)
      expect(response.json['name']).to eq(character.name)
    end

    it "has single gallery when present" do
      character.galleries << gallery
      get :show, params: { id: character.id }
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(1)
    end

    it "has single gallery when icon present" do
      character.update!(default_icon: create(:icon, user: user))
      get :show, params: { id: character.id }
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(1)
    end

    it "returns icons in keyword order" do
      gallery.icons << create(:icon, keyword: 'zzz', user: user)
      gallery.icons << create(:icon, keyword: 'yyy', user: user)
      gallery.icons << create(:icon, keyword: 'xxx', user: user)
      expect(gallery.icons.pluck(:keyword)).to eq(['xxx', 'yyy', 'zzz'])
      character.galleries << gallery
      get :show, params: { id: character.id }
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(1)
      expect(response.json['galleries'][0]['icons'].map { |i| i['keyword'] }).to eq(['xxx', 'yyy', 'zzz'])
    end

    it "has associations when present", :show_in_doc do
      calias
      character.galleries << create(:gallery, user: user, icon_count: 2)
      character.galleries << create(:gallery, user: user, icon_count: 1)
      get :show, params: { id: character.id }
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(2)
      expect(response.json['aliases'].size).to eq(1)
      expect(response.json['aliases'].first['id']).to eq(calias.id)
    end

    it "has galleries when icon_picker_grouping is false" do
      user.update!(icon_picker_grouping: false)
      gallery2 = create(:gallery, user: user)
      character.galleries << gallery
      character.galleries << gallery2
      gallery.icons << create(:icon, user: user)
      gallery2.icons << create(:icon, user: user)
      get :show, params: { id: character.id }
      expect(response).to have_http_status(200)
      expect(response.json['galleries'].size).to eq(1)
    end

    it "requires post to exist when provided a post_id", :show_in_doc do
      get :show, params: { id: character.id, post_id: 0 }
      expect(response).to have_http_status(422)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("Post could not be found.")
    end

    it "requires post to have permission when provided a post_id", :show_in_doc do
      post = create(:post, privacy: Concealable::PRIVATE, character: character, user: user)
      get :show, params: { id: post.character_id, post_id: post.id }
      expect(response).to have_http_status(:forbidden)
      expect(response.json['errors'].size).to eq(1)
      expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    it "includes alias_id_for_post field when given post_id" do
      post = create(:post, user: user)
      get :show, params: { id: character.id, post_id: post.id }
      expect(response).to have_http_status(200)
      expect(response.json).to have_key('alias_id_for_post')
      expect(response.json['alias_id_for_post']).to be_nil
    end

    it "sets correct alias_id_for_post when given post_id with recently used alias in post", :show_in_doc do
      post = create(:post, user: user, character: character, character_alias: calias)
      get :show, params: { id: character.id, post_id: post.id }
      expect(response).to have_http_status(200)
      expect(response.json).to have_key('alias_id_for_post')
      expect(response.json['alias_id_for_post']).to eq(calias.id)
    end

    it "sets correct alias_id_for_post when given post_id with recently used alias in post" do
      post = create(:post, user: user, character: character)
      create(:reply, post: post, user: user, character: character, character_alias: calias)
      get :show, params: { id: character.id, post_id: post.id }
      expect(response).to have_http_status(200)
      expect(response.json).to have_key('alias_id_for_post')
      expect(response.json['alias_id_for_post']).to eq(calias.id)
    end
  end

  describe "PUT update" do
    let(:user) { create(:user) }
    let(:character) { create(:character, user: user, default_icon: icon) }
    let(:icon) { create(:icon, user: user) }
    let(:new_icon) { create(:icon, user: user)}

    it "requires login", :show_in_doc do
      put :update, params: { id: -1 }
      expect(response).to have_http_status(401)
      expect(response.json['errors'][0]['message']).to eq("You must be logged in to view that page.")
    end

    it "requires permission", :show_in_doc do
      login
      put :update, params: { id: character.id }
      expect(response).to have_http_status(403)
      expect(response.json['errors'][0]['message']).to eq("You do not have permission to perform this action.")
    end

    context "when logged in" do
      before(:each) { login_as(user) }

      it "requires valid character", :show_in_doc do
        put :update, params: { id: -1 }
        expect(response).to have_http_status(404)
        expect(response.json['errors'][0]['message']).to eq("Character could not be found.")
      end

      it "does not change icon if invalid icon provided" do
        put :update, params: { id: character.id, character: {default_icon_id: -1} }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq("Default icon could not be found")
        expect(character.reload.default_icon_id).to eq(icon.id)
      end

      it "does not change icon if someone else's icon provided" do
        put :update, params: { id: character.id, character: {default_icon_id: create(:icon).id} }
        expect(response).to have_http_status(422)
        expect(response.json['errors'][0]['message']).to eq("Default icon must be yours")
        expect(character.reload.default_icon_id).to eq(icon.id)
      end

      it "removes icon successfully with empty icon_id" do
        put :update, params: { id: character.id, character: {default_icon_id: ''} }
        expect(response.status).to eq(200)
        expect(response.json['name']).to eq(character.name)
        expect(character.reload.default_icon_id).to be_nil
      end

      it "changes icon if valid", :show_in_doc do
        put :update, params: { id: character.id, character: {default_icon_id: new_icon.id} }

        expect(response.status).to eq(200)
        expect(response.json['name']).to eq(character.name)
        expect(character.reload.default_icon_id).to eq(new_icon.id)
      end

      it "handles validation failures and invalid params", :show_in_doc do
        put :update, params: { id: character.id, character: {default_icon_id: new_icon.id, name: '', user_id: nil} }

        expect(response.status).to eq(422)
        expect(response.json['errors'][0]['message']).to eq("Name can't be blank")
        expect(character.reload.default_icon_id).to eq(icon.id)
        expect(character.reload.user_id).to eq(icon.user_id)
      end
    end
  end

  describe "POST reorder" do
    let(:ordered_ids) { :ordered_characters_gallery_ids }
    let(:ids_name) { 'characters_gallery_ids' }
    let(:child_name) { 'character gallery' }

    include_examples "reorder", :character, :characters_gallery
  end
end
