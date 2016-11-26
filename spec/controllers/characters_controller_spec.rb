require "spec_helper"

RSpec.describe CharactersController do
  describe "GET index" do
    it "requires login without an id" do
      get :index
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid id" do
      get :index, user_id: -1
      expect(response).to redirect_to(users_url)
      expect(flash[:error]).to eq("User could not be found.")
    end

    it "succeeds with an id" do
      user = create(:user)
      get :index, user_id: user.id
      expect(response.status).to eq(200)
    end

    it "succeeds when logged in" do
      login
      get :index
      expect(response.status).to eq(200)
    end

    it "succeeds with an id when logged in" do
      user = create(:user)
      login
      get :index, user_id: user.id
      expect(response.status).to eq(200)
    end

    it "sets user's characters" do
      user = create(:user)
      characters = 4.times.collect do create(:character, user: user) end
      create(:character)
      login_as(user)
      get :index
      expect(assigns(:characters)).to match_array(characters)
    end

    it "sets other user's characters" do
      user = create(:user)
      characters = 4.times.collect do create(:character, user: user) end
      create(:character)
      get :index, user_id: user.id
      expect(assigns(:characters)).to match_array(characters)
    end

    it "sets other user's characters" do
      user = create(:user)
      characters = 4.times.collect do create(:character, user: user) end
      create(:character)
      login
      get :index, user_id: user.id
      expect(assigns(:characters)).to match_array(characters)
    end

    it "does something with character groups" do
      skip "Character groups need to be refactored"
    end
  end

  describe "GET new" do
    it "requires login" do
      get :new
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "succeeds when logged in" do
      login
      get :new
      expect(response.status).to eq(200)
    end

    it "sets correct variables" do
      user = create(:user)
      templates = 2.times.collect do create(:template, user: user) end
      names = ['— Create New Template —'] + templates.map(&:name)
      create(:template)

      login_as(user)
      get :new

      expect(assigns(:page_title)).to eq("New Character")
      expect(controller.gon.character_id).to eq('')
      expect(assigns(:templates).map(&:name)).to match_array(names)
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "fails with missing params" do
      login
      post :create
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "fails with invalid params" do
      login
      post :create, character: {}
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "succeeds when valid" do
      expect(Character.count).to eq(0)
      test_name = 'Test character'

      user_id = login
      post :create, character: {name: test_name}

      expect(response).to redirect_to(assigns(:character))
      expect(flash[:success]).to eq("Character saved successfully.")
      expect(Character.count).to eq(1)
      expect(assigns(:character).name).to eq(test_name)
      expect(assigns(:character).user_id).to eq(user_id)
    end

    it "creates new templates when specified" do
      expect(Template.count).to eq(0)
      login
      post :create, character: {template_id: 0, new_template_name: 'TemplateTest', name: 'Test'}
      expect(Template.count).to eq(1)
      expect(Template.first.name).to eq('TemplateTest')
      expect(assigns(:character).template_id).to eq(Template.first.id)
    end

    it "sets correct variables when invalid" do
      user = create(:user)
      templates = 2.times.collect do create(:template, user: user) end
      names = ['— Create New Template —'] + templates.map(&:name)
      create(:template)

      login_as(user)
      post :create, character: {}

      expect(controller.gon.character_id).to eq('')
      expect(assigns(:templates).map(&:name)).to match_array(names)
    end
  end

  describe "GET show" do
    context "html" do
      it "requires valid character" do
        get :show, id: -1
        expect(response).to redirect_to(characters_url)
        expect(flash[:error]).to eq("Character could not be found.")
      end

      it "should succeed when logged out" do
        character = create(:character)
        get :show, id: character.id
        expect(response.status).to eq(200)
      end

      it "should succeed when logged in" do
        character = create(:character)
        login
        get :show, id: character.id
        expect(response.status).to eq(200)
      end

      it "should set correct variables" do
        character = create(:character)
        posts = 26.times.collect do create(:post, character: character, user: character.user) end
        get :show, id: character.id
        expect(response.status).to eq(200)
        expect(assigns(:page_title)).to eq(character.name)
        expect(assigns(:posts).size).to eq(25)
        expect(assigns(:posts)).to match_array(Post.where(character_id: character.id).order('tagged_at desc').limit(25))
      end
    end

    context "json" do
      it "requires valid character" do
        get :show, id: -1, format: :json
        expect(response).to redirect_to(characters_url)
        expect(flash[:error]).to eq("Character could not be found.")
      end

      it "should succeed when logged out" do
        character = create(:character)
        get :show, id: character.id, format: :json
        expect(response.status).to eq(200)
        expect(response.json['name']).to eq(character.name)
      end

      it "should succeed when logged in" do
        character = create(:character)
        login
        get :show, id: character.id, format: :json
        expect(response.status).to eq(200)
        expect(response.json['name']).to eq(character.name)
      end

      it "has galleries when present" do
        character = create(:character)
        character.galleries << create(:gallery, user: character.user, icon_count: 2)
        character.galleries << create(:gallery, user: character.user, icon_count: 1)
        get :show, id: character.id, format: :json
        expect(response.status).to eq(200)
        expect(response.json['galleries'].size).to eq(2)
      end

      it "has galleries when icon_picker_grouping is false" do
        user = create(:user, icon_picker_grouping: false)
        character = create(:character, user: user)
        character.galleries << create(:gallery, user: user)
        character.galleries << create(:gallery, user: user)
        login_as(user)
        get :show, id: character.id, format: :json
        expect(response.status).to eq(200)
        expect(response.json['galleries'].size).to eq(1)
      end

      it "has single gallery when present" do
        character = create(:character)
        character.galleries << create(:gallery, user: character.user)
        get :show, id: character.id, format: :json
        expect(response.status).to eq(200)
        expect(response.json['galleries'].size).to eq(1)
      end

      it "has single gallery when icon present" do
        character = create(:character)
        character.default_icon = create(:icon, user: character.user)
        character.save
        get :show, id: character.id, format: :json
        expect(response.status).to eq(200)
        expect(response.json['galleries'].size).to eq(1)
      end
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid character id" do
      login
      get :edit, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires character with permissions" do
      login
      get :edit, id: create(:character).id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("You do not have permission to edit that character.")
    end

    it "succeeds when logged in" do
      character = create(:character)
      login_as(character.user)
      get :edit, id: character.id
      expect(response.status).to eq(200)
    end

    it "sets correct variables" do
      user = create(:user)
      character = create(:character, user: user)
      templates = 2.times.collect do create(:template, user: user) end
      names = ['— Create New Template —'] + templates.map(&:name)
      create(:template)

      login_as(user)
      get :edit, id: character.id

      expect(assigns(:page_title)).to eq("Edit Character: #{character.name}")
      expect(controller.gon.character_id).to eq(character.id)
      expect(assigns(:templates).map(&:name)).to match_array(names)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid character id" do
      login
      put :update, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires character with permissions" do
      login
      put :update, id: create(:character).id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("You do not have permission to edit that character.")
    end

    it "fails with invalid params" do
      character = create(:character)
      login_as(character.user)
      put :update, id: character.id, character: {name: ''}
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
    end

    it "fails with invalid template params" do
      character = create(:character)
      login_as(character.user)
      new_name = character.name + 'aaa'
      put :update, id: character.id, character: {template_id: 0, new_template_name: '', name: new_name}
      expect(response.status).to eq(200)
      expect(flash[:error]).to eq("Your character could not be saved.")
      expect(character.reload.name).not_to eq(new_name)
    end

    it "succeeds when valid" do
      character = create(:character)
      login_as(character.user)
      new_name = character.name + 'aaa'
      put :update, id: character.id, character: {name: new_name}

      expect(response).to redirect_to(assigns(:character))
      expect(flash[:success]).to eq("Character saved successfully.")
      character.reload
      expect(character.name).to eq(new_name)
    end

    it "creates new templates when specified" do
      expect(Template.count).to eq(0)
      character = create(:character)
      login_as(character.user)
      put :update, id: character.id, character: {template_id: 0, new_template_name: 'Test'}
      expect(Template.count).to eq(1)
      expect(Template.first.name).to eq('Test')
      expect(character.reload.template_id).to eq(Template.first.id)
    end

    it "sets correct variables when invalid" do
      user = create(:user)
      templates = 2.times.collect do create(:template, user: user) end
      names = ['— Create New Template —'] + templates.map(&:name)
      create(:template)

      login_as(user)
      post :create, character: {}

      expect(controller.gon.character_id).to eq('')
      expect(assigns(:templates).map(&:name)).to match_array(names)
    end
  end

  describe "POST icon" do
    it "requires login" do
      post :icon, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid character" do
      login
      post :icon, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires permission" do
      user = create(:user)
      login_as(user)
      character = create(:character)
      expect(character.user_id).not_to eq(user.id)
      post :icon, id: character.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("You do not have permission to edit that character.")
    end

    it "does not change icon if invalid icon provided" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      login_as(character.user)
      post :icon, id: character.id
      expect(response.status).to eq(200)
      expect(response.json).to eq({})
      expect(character.reload.default_icon_id).to eq(icon.id)
    end

    it "does not change icon if icon without permission provided" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      new_icon = create(:icon)
      login_as(character.user)
      post :icon, id: character.id, icon_id: new_icon.id
      expect(response.status).to eq(200)
      expect(response.json).to eq({})
      expect(character.reload.default_icon_id).to eq(icon.id)
    end

    it "changes icon if valid" do
      icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
      new_icon = create(:icon, user: icon.user)
      login_as(character.user)

      post :icon, id: character.id, icon_id: new_icon.id

      expect(response.status).to eq(200)
      expect(response.json).to eq({})
      expect(character.reload.default_icon_id).to eq(new_icon.id)
    end
  end

  describe "GET facecasts" do
    it "does not require login" do
      get :facecasts
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("Facecasts")
    end

    it "sets correct variables for facecast name sort" do
      chars = 3.times.collect do create(:character, pb: SecureRandom.urlsafe_base64) end
      get :facecasts
      expect(assigns(:pbs).keys).to match_array(chars.map(&:pb))
    end

    it "sets correct variables for character name sort: character only" do
      chars = 3.times.collect do create(:character, pb: SecureRandom.urlsafe_base64) end
      get :facecasts, sort: 'name'
      expect(assigns(:pbs).keys).to match_array(chars)
    end

    it "sets correct variables for character name sort: template only" do
      chars = 3.times.collect do create(:template_character, pb: SecureRandom.urlsafe_base64) end
      get :facecasts, sort: 'name'
      expect(assigns(:pbs).keys).to match_array(chars.map(&:template))
    end

    it "sets correct variables for character name sort: character and template mixed" do
      chars = 3.times.collect do create(:template_character, pb: SecureRandom.urlsafe_base64) end
      chars += 3.times.collect do create(:character, pb: SecureRandom.urlsafe_base64) end
      get :facecasts, sort: 'name'
      expect(assigns(:pbs).keys).to match_array(chars.map { |c| c.template || c })
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires valid character" do
      login
      delete :destroy, id: -1
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires permission" do
      user = create(:user)
      login_as(user)
      character = create(:character)
      expect(character.user_id).not_to eq(user.id)
      delete :destroy, id: character.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:error]).to eq("You do not have permission to edit that character.")
    end

    it "succeeds" do
      character = create(:character)
      login_as(character.user)
      delete :destroy, id: character.id
      expect(response).to redirect_to(characters_url)
      expect(flash[:success]).to eq("Character deleted successfully.")
      expect(Character.find_by_id(character.id)).to be_nil
    end
  end
end
