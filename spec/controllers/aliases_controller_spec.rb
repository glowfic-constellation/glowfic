RSpec.describe AliasesController do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:reader) { create(:reader_user) }
  let(:character) { create(:character) }
  let(:calias) { create(:alias, character: character) }

  describe "GET new" do
    it "requires login" do
      get :new, params: { character_id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(reader)
      get :new, params: { character_id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create aliases.")
    end

    it "requires valid character" do
      login_as(user)
      get :new, params: { character_id: -1 }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires your character" do
      login_as(user)
      get :new, params: { character_id: character.id }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("You do not have permission to modify this character.")
    end

    it "succeeds" do
      login_as(character.user)
      get :new, params: { character_id: character.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Alias: #{character.name}")
      expect(assigns(:alias)).to be_a_new_record
      expect(assigns(:alias).character).to eq(character)
    end
  end

  describe "POST create" do
    it "requires login" do
      post :create, params: { character_id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(reader)
      post :create, params: { character_id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create aliases.")
    end

    it "requires valid character" do
      login_as(user)
      post :create, params: { character_id: -1 }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires your character" do
      login_as(user)
      post :create, params: { character_id: character.id }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("You do not have permission to modify this character.")
    end

    it "fails with missing params" do
      login_as(character.user)
      post :create, params: { character_id: character.id }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Alias could not be created because of the following problems:")
      expect(assigns(:page_title)).to eq("New Alias: #{character.name}")
      expect(assigns(:alias)).to be_a_new_record
    end

    it "fails with invalid params" do
      login_as(character.user)
      post :create, params: { character_id: character.id, character_alias: { name: '' } }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Alias could not be created because of the following problems:")
      expect(assigns(:page_title)).to eq("New Alias: #{character.name}")
      expect(assigns(:alias)).to be_a_new_record
    end

    it "succeeds when valid" do
      test_name = 'Test character alias'
      login_as(character.user)

      expect {
        post :create, params: {
          character_id: character.id,
          character_alias: { name: test_name },
        }
      }.to change { CharacterAlias.count }.by(1)

      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:success]).to eq("Alias created.")
      expect(character.aliases.count).to eq(1)
      expect(assigns(:alias).name).to eq(test_name)
    end
  end

  describe "GET edit" do
    it "requires login" do
      get :edit, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(reader)
      get :edit, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create aliases.")
    end

    it "requires valid character" do
      login_as(user)
      get :edit, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires your character" do
      login_as(user)
      get :edit, params: { id: calias.id, character_id: character.id }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("You do not have permission to modify this character.")
    end

    it "requires valid alias" do
      login_as(character.user)
      get :edit, params: { id: -1, character_id: character.id }
      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:error]).to eq("Alias could not be found.")
    end

    it "requires aliases to match character" do
      calias = create(:alias)
      login_as(character.user)
      get :edit, params: { id: calias.id, character_id: character.id }
      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:error]).to eq("Alias could not be found for that character.")
    end

    it "succeeds" do
      login_as(character.user)
      get :edit, params: { id: calias.id, character_id: character.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("Edit Alias: #{calias.name}")
      expect(assigns(:alias)).to eq(calias)
      expect(assigns(:alias).character).to eq(character)
    end
  end

  describe "PUT update" do
    it "requires login" do
      put :update, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(reader)
      put :update, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create aliases.")
    end

    it "requires valid character" do
      login_as(user)
      put :update, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires your character" do
      login_as(user)
      put :update, params: { id: calias.id, character_id: character.id }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("You do not have permission to modify this character.")
    end

    it "requires valid alias" do
      login_as(character.user)
      put :update, params: { id: -1, character_id: character.id }
      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:error]).to eq("Alias could not be found.")
    end

    it "requires aliases to match character" do
      calias = create(:alias)
      login_as(character.user)
      put :update, params: { id: calias.id, character_id: character.id }
      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:error]).to eq("Alias could not be found for that character.")
    end

    it "fails with invalid params" do
      login_as(character.user)
      put :update, params: { id: calias.id, character_id: character.id, character_alias: { name: '' } }
      expect(response.status).to eq(200)
      expect(flash[:error][:message]).to eq("Alias could not be updated because of the following problems:")
      expect(assigns(:page_title)).to eq("Edit Alias: #{calias.name}")
    end

    it "succeeds when valid" do
      test_name = 'Test character alias'
      login_as(character.user)

      put :update, params: {
        id: calias.id,
        character_id: character.id,
        character_alias: { name: test_name },
      }

      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:success]).to eq("Alias updated.")
      expect(character.aliases.count).to eq(1)
      expect(assigns(:alias).name).to eq(test_name)
    end
  end

  describe "DELETE destroy" do
    it "requires login" do
      delete :destroy, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires full account" do
      login_as(reader)
      delete :destroy, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("You do not have permission to create aliases.")
    end

    it "requires valid character" do
      login_as(user)
      delete :destroy, params: { id: -1, character_id: -1 }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "requires your character" do
      login_as(user)
      delete :destroy, params: { id: -1, character_id: character.id }
      expect(response).to redirect_to(user_characters_url(user.id))
      expect(flash[:error]).to eq("You do not have permission to modify this character.")
    end

    it "requires valid alias" do
      login_as(character.user)
      delete :destroy, params: { id: -1, character_id: character.id }
      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:error]).to eq("Alias could not be found.")
    end

    it "requires aliases to match character" do
      calias = create(:alias)
      login_as(character.user)
      delete :destroy, params: { id: calias.id, character_id: character.id }
      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:error]).to eq("Alias could not be found for that character.")
    end

    it "succeeds" do
      reply = create(:reply, user: character.user, character: character, character_alias: calias)
      draft = create(:reply_draft, user: character.user, character: character, character_alias: calias)
      login_as(character.user)
      perform_enqueued_jobs(only: UpdateModelJob) do
        delete :destroy, params: { id: calias.id, character_id: character.id }
      end
      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:success]).to eq("Alias removed.")
      expect(draft.reload.character_alias_id).to be_nil
      expect(reply.reload.character_alias_id).to be_nil
    end

    it "handles destroy failure" do
      reply = create(:reply, user: character.user, character: character, character_alias: calias)
      login_as(character.user)

      allow(CharacterAlias).to receive(:find_by).and_call_original
      allow(CharacterAlias).to receive(:find_by).with({ id: calias.id.to_s }).and_return(calias)
      allow(calias).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      expect(calias).to receive(:destroy!)

      delete :destroy, params: { id: calias.id, character_id: calias.character.id }

      expect(response).to redirect_to(edit_character_path(calias.character))
      expect(flash[:error]).to eq("Alias could not be deleted.")
      expect(reply.reload.character_alias).to eq(calias)
    end
  end
end
