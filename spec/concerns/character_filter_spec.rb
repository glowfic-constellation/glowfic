RSpec.describe CharacterFilter do
  # Test through CharactersController which includes CharacterFilter
  describe CharactersController do
    describe "#character_split" do
      it "defaults to template for logged-out users" do
        get :index
        expect(controller.send(:character_split)).to eq('template')
      end

      it "uses param when logged out" do
        get :index, params: { character_split: 'none' }
        expect(controller.send(:character_split)).to eq('none')
      end

      it "uses session when logged out and no param" do
        session[:character_split] = 'none'
        get :index
        expect(controller.send(:character_split)).to eq('none')
      end

      it "uses user default when logged in" do
        user = create(:user, default_character_split: 'none')
        login_as(user)
        get :index
        expect(controller.send(:character_split)).to eq('none')
      end

      it "uses param over user default when logged in" do
        user = create(:user, default_character_split: 'none')
        login_as(user)
        get :index, params: { character_split: 'template' }
        expect(controller.send(:character_split)).to eq('template')
      end
    end

    describe "#show_retired" do
      it "defaults to true for logged-out users" do
        get :index
        expect(controller.send(:show_retired)).to be true
      end

      it "respects false param when logged out" do
        get :index, params: { retired: 'false' }
        expect(controller.send(:show_retired)).to be false
      end

      it "uses user default when logged in" do
        user = create(:user, default_hide_retired_characters: true)
        login_as(user)
        get :index
        expect(controller.send(:show_retired)).to be false
      end

      it "uses param over user default when logged in" do
        user = create(:user, default_hide_retired_characters: true)
        login_as(user)
        get :index, params: { retired: 'true' }
        expect(controller.send(:show_retired)).to be true
      end
    end
  end
end
