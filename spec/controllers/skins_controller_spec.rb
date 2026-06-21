RSpec.describe SkinsController do
  describe "GET index" do
    it "requires login" do
      get :index
      expect(response).to redirect_to(root_url)
    end

    it "shows only your own skins" do
      user = create(:user)
      mine = create(:skin, user: user, name: 'Mine')
      create(:skin, name: 'Someone else')
      login_as(user)
      get :index
      expect(response.status).to eq(200)
      expect(assigns(:skins)).to eq([mine])
    end
  end

  describe "GET gallery" do
    it "lists public skins without login" do
      pub = create(:skin, public: true)
      create(:skin, public: false)
      get :gallery
      expect(response.status).to eq(200)
      expect(assigns(:skins)).to eq([pub])
    end
  end

  describe "POST create" do
    it "creates a skin and stores sanitized CSS" do
      user = create(:user)
      login_as(user)
      expect {
        post :create, params: { skin: { name: 'Compact', css: '.post-container { color: red !important; }' } }
      }.to change { Skin.count }.by(1)
      skin = Skin.last
      expect(skin.user).to eq(user)
      expect(skin.sanitized_css).to include('color: red')
      expect(skin.sanitized_css).not_to include('!important')
    end

    it "re-renders the form when the skin is invalid" do
      login
      expect {
        post :create, params: { skin: { name: '', css: '.a { color: red; }' } }
      }.not_to change { Skin.count }
      expect(response).to render_template(:new)
    end
  end

  describe "GET show" do
    it "redirects when the skin cannot be found" do
      login
      get :show, params: { id: -1 }
      expect(response).to redirect_to(skins_path)
      expect(flash[:error]).to be_present
    end
  end

  describe "PUT update" do
    it "re-renders the form when the update is invalid" do
      user = create(:user)
      skin = create(:skin, user: user, name: 'Keep')
      login_as(user)
      put :update, params: { id: skin.id, skin: { name: '' } }
      expect(response).to render_template(:edit)
      expect(skin.reload.name).to eq('Keep')
    end

    it "requires edit permission" do
      skin = create(:skin)
      login
      put :update, params: { id: skin.id, skin: { name: 'Hacked' } }
      expect(skin.reload.name).not_to eq('Hacked')
    end

    it "updates your own skin" do
      user = create(:user)
      skin = create(:skin, user: user)
      login_as(user)
      put :update, params: { id: skin.id, skin: { name: 'Renamed' } }
      expect(skin.reload.name).to eq('Renamed')
    end
  end

  describe "DELETE destroy" do
    it "deletes your own skin" do
      user = create(:user)
      skin = create(:skin, user: user)
      login_as(user)
      expect { delete :destroy, params: { id: skin.id } }.to change { Skin.count }.by(-1)
    end

    it "reports an error and keeps the skin when destruction fails" do
      user = create(:user)
      skin = create(:skin, user: user)
      login_as(user)
      allow_any_instance_of(Skin).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed.new('nope', skin))
      expect { delete :destroy, params: { id: skin.id } }.not_to change { Skin.count }
      expect(response).to redirect_to(skins_path)
      expect(flash[:error]).to be_present
    end
  end

  describe "POST use / DELETE clear" do
    it "sets and clears the active skin" do
      user = create(:user)
      skin = create(:skin, user: user)
      login_as(user)

      post :use, params: { id: skin.id }
      expect(user.reload.skin_id).to eq(skin.id)

      delete :clear
      expect(user.reload.skin_id).to be_nil
    end

    it "does not let you use a private skin you cannot see" do
      skin = create(:skin, public: false)
      user = create(:user)
      login_as(user)
      post :use, params: { id: skin.id }
      expect(user.reload.skin_id).to be_nil
    end
  end

  describe "POST fork" do
    it "copies a visible skin into your own skins" do
      other = create(:user)
      skin = create(:skin, user: other, public: true, name: 'Original')
      user = create(:user)
      login_as(user)
      expect { post :fork, params: { id: skin.id } }.to change { user.skins.count }.by(1)
      expect(user.skins.last.name).to eq('Original (copy)')
    end

    it "reports an error when the copy cannot be saved" do
      skin = create(:skin, public: true)
      user = create(:user)
      login_as(user)
      allow_any_instance_of(Skin).to receive(:save).and_return(false)
      expect { post :fork, params: { id: skin.id } }.not_to change { Skin.count }
      expect(response).to redirect_to(skin_path(skin))
      expect(flash[:error]).to be_present
    end
  end

  describe "moderation" do
    let(:dangerous_css) { '.post-container { color: red !important; }' }

    it "requires approve permission for the review queue" do
      login
      get :review
      expect(response).to redirect_to(skins_path)
    end

    it "lists pending dangerous public skins for mods" do
      pending = create(:skin, public: true, css: dangerous_css)
      login_as(create(:mod_user))
      get :review
      expect(response.status).to eq(200)
      expect(assigns(:skins)).to eq([pending])
    end

    it "lets a mod approve a skin so readers get the raw CSS" do
      skin = create(:skin, public: true, css: dangerous_css)
      mod = create(:mod_user)
      login_as(mod)
      post :approve, params: { id: skin.id }
      expect(skin.reload.approved?).to be(true)
      expect(skin.approved_by).to eq(mod)
    end

    it "does not let a non-mod approve" do
      skin = create(:skin, public: true, css: dangerous_css)
      login
      post :approve, params: { id: skin.id }
      expect(skin.reload.approved?).to be(false)
    end

    it "lets a mod reject (and unlist) a skin" do
      skin = create(:skin, public: true, css: dangerous_css)
      login_as(create(:mod_user))
      post :reject, params: { id: skin.id }
      skin.reload
      expect(skin.approved?).to be(false)
      expect(skin.public).to be(false)
    end
  end

  context "with render_views" do
    render_views

    let(:user) { create(:user) }
    let!(:skin) { create(:skin, user: user, name: 'Renderable', public: true) }

    before(:each) { login_as(user) }

    it "renders index, gallery, show, new and edit" do
      get :index
      expect(response.status).to eq(200)
      expect(response.body).to include('Renderable')

      get :gallery
      expect(response.status).to eq(200)

      get :show, params: { id: skin.id }
      expect(response.status).to eq(200)

      get :new
      expect(response.status).to eq(200)

      get :edit, params: { id: skin.id }
      expect(response.status).to eq(200)
    end
  end
end
