require "spec_helper"
require "support/shared_examples/controller"

RSpec.describe AliasesController do
  include ActiveJob::TestHelper

  describe "GET new" do
    let(:redirect_override) { user_characters_url(user) }

    include_examples 'GET new with parent validations', 'character'

    it "succeeds" do
      character = create(:character)
      login_as(character.user)
      get :new, params: { character_id: character.id }
      expect(response.status).to eq(200)
      expect(assigns(:page_title)).to eq("New Alias: #{character.name}")
      expect(assigns(:alias)).to be_a_new_record
      expect(assigns(:alias).character).to eq(character)
    end
  end

  describe "POST create" do
    let(:redirect_override) { user_characters_url(user) }

    include_examples 'POST create with parent validations', 'character', 'CharacterAlias', 'alias'

    it "succeeds when valid" do
      expect(CharacterAlias.count).to eq(0)
      test_name = 'Test character alias'

      character = create(:character)
      login_as(character.user)

      post :create, params: { character_id: character.id, character_alias: {name: test_name} }

      expect(response).to redirect_to(edit_character_url(character))
      expect(flash[:success]).to eq("Alias created.")
      expect(CharacterAlias.count).to eq(1)
      expect(character.aliases.count).to eq(1)
      expect(assigns(:alias).name).to eq(test_name)
    end
  end

  describe "DELETE destroy" do
    let(:redirect_override) { user_characters_url(user) }
    let(:parent_redirect) { edit_character_url(parent) }

    include_examples 'DELETE destroy with parent validations', 'character', 'CharacterAlias', 'alias'

    it "requires valid character" do
      login_as(user)
      delete :destroy, params: { id: -1, parent_key => -1 }
      expect(response).to redirect_to(parent_redirect)
      expect(flash[:error]).to eq("Character could not be found.")
    end

    it "succeeds" do
      calias = create(:alias)
      reply = create(:reply, user: calias.character.user, character: calias.character, character_alias: calias)
      draft = create(:reply_draft, user: calias.character.user, character: calias.character, character_alias: calias)
      login_as(calias.character.user)
      perform_enqueued_jobs(only: UpdateModelJob) do
        delete :destroy, params: { id: calias.id, character_id: calias.character_id }
      end
      expect(response).to redirect_to(edit_character_url(calias.character))
      expect(flash[:success]).to eq("Alias removed.")
      expect(draft.reload.character_alias_id).to be_nil
      expect(reply.reload.character_alias_id).to be_nil
    end

    it "handles destroy failure" do
      calias = create(:alias)
      reply = create(:reply, user: calias.character.user, character: calias.character, character_alias: calias)
      login_as(calias.character.user)
      expect_any_instance_of(CharacterAlias).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed, 'fake error')
      delete :destroy, params: { id: calias.id, character_id: calias.character.id }
      expect(response).to redirect_to(edit_character_path(calias.character))
      expect(flash[:error]).to eq({message: "Alias could not be deleted.", array: []})
      expect(reply.reload.character_alias).to eq(calias)
    end
  end
end
