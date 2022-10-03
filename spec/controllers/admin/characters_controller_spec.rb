RSpec.describe Admin::CharactersController do
  include ActiveJob::TestHelper

  let(:mod) { create(:mod_user) }
  let(:admin) { create(:admin_user) }

  describe "GET #relocate" do
    it "requires login" do
      get :relocate
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      login
      get :relocate
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You do not have permission to view that page.")
    end

    it "loads for mods" do
      login_as(mod)
      get :relocate
      expect(response).to have_http_status(200)
    end

    it "loads for admins" do
      login_as(admin)
      get :relocate
      expect(response).to have_http_status(200)
    end
  end

  describe "POST #do_relocate" do
    let!(:old_user) { create(:user) }
    let!(:new_user) { create(:user) }
    let!(:characters) { Character.where(id: create_list(:character, 10, user: old_user).map(&:id)) }
    let!(:posts) { Post.where(id: characters.map { |c| create(:post, user: old_user, character: c).id }) }
    let!(:replies) { Reply.where(id: characters.map { |c| create_list(:reply, 2, character: c, user: old_user).map(&:id) }.flatten) }

    it "requires login" do
      post :do_relocate, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires permission" do
      login
      post :do_relocate, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You do not have permission to view that page.")
    end

    it "requires new user" do
      login_as(mod)
      post :do_relocate, params: { user_id: -1 }
      expect(response).to redirect_to(relocate_characters_url)
      expect(flash[:error]).to eq("New user could not be found.")
    end

    it "requires characters" do
      login_as(mod)
      post :do_relocate, params: { user_id: new_user.id, character_id: -1 }
      expect(response).to redirect_to(relocate_characters_url)
      expect(flash[:error]).to eq("Characters could not be found.")
    end

    it "requires valid characters" do
      login_as(mod)
      post :do_relocate, params: { user_id: new_user.id, character_id: '-1, 0' }
      expect(response).to redirect_to(relocate_characters_url)
      expect(flash[:error]).to eq("Characters could not be found.")
    end

    describe "preview" do
      it "loads for mods" do
        login_as(mod)
        post :do_relocate, params: { button_preview: 'Preview', character_id: characters.map(&:id).join(', '), user_id: new_user.id }
        expect(response).to have_http_status(200)
        expect(assigns(:char_ids)).to eq(characters.map(&:id))
      end

      it "loads for admins" do
        login_as(admin)
        post :do_relocate, params: { button_preview: 'Preview', character_id: characters.map(&:id).join(', '), user_id: new_user.id }
        expect(response).to have_http_status(200)
        expect(assigns(:char_ids)).to eq(characters.map(&:id))
      end
    end

    describe "perform" do
      before(:each) do
        Post.auditing_enabled = true
        Reply.auditing_enabled = true
        Character.auditing_enabled = true
      end

      after(:each) do
        Post.auditing_enabled = false
        Reply.auditing_enabled = false
        Character.auditing_enabled = false
      end

      it "works as mod" do
        login_as(mod)
        perform_enqueued_jobs do
          post :do_relocate, params: { character_id: characters.map(&:id).join(', '), user_id: new_user.id }
        end
        expect(response).to redirect_to(admin_url)
        expect(flash[:success]).to eq("Characters relocated.")

        expect(assigns(:char_ids)).to match_array(characters.map(&:id))
        expect(assigns(:characters)).to match_array(characters)
        expect(assigns(:new_user)).to eq(new_user)

        expect(characters.reload.pluck(:user_id).uniq).to eq([new_user.id])
        expect(posts.reload.pluck(:user_id).uniq).to eq([new_user.id])
        expect(replies.reload.pluck(:user_id).uniq).to eq([new_user.id])
        expect(posts.first.audits.last.user).to eq(mod)
      end

      it "works as admin" do
        login_as(admin)
        perform_enqueued_jobs do
          post :do_relocate, params: { character_id: characters.map(&:id).join(', '), user_id: new_user.id }
        end
        expect(response).to redirect_to(admin_url)
        expect(flash[:success]).to eq("Characters relocated.")

        expect(assigns(:char_ids)).to match_array(characters.map(&:id))
        expect(assigns(:characters)).to match_array(characters)
        expect(assigns(:new_user)).to eq(new_user)

        expect(characters.reload.pluck(:user_id).uniq).to eq([new_user.id])
        expect(posts.reload.pluck(:user_id).uniq).to eq([new_user.id])
        expect(replies.reload.pluck(:user_id).uniq).to eq([new_user.id])
        expect(characters.first.audits.last.user).to eq(admin)
      end
    end
  end
end
