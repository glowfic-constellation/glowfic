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

  describe "GET edit" do
    it "requires login" do
      get :edit, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, id: -1
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
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
      skip "POST icon does not yet validate icon permission"
    end

    it "changes icon if valid" do
      icon = create(:icon)
      new_icon = create(:icon)
      character = create(:character, user: icon.user, default_icon_id: icon.id)
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
