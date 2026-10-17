RSpec.describe OauthClientsController do
  let(:user) { create(:user) }
  let!(:application) { create(:oauth_application, owner: user) }

  it "requires login" do
    get :index
    expect(response).to redirect_to(root_url)
  end

  context "when logged in" do
    before(:each) { login_as(user) }

    describe "GET index" do
      it "lists only the user's applications" do
        create(:oauth_application)
        get :index
        expect(response).to have_http_status(200)
        expect(assigns(:applications)).to eq([application])
      end
    end

    describe "GET show" do
      it "succeeds without revealing the secret" do
        get :show, params: { id: application.id }
        expect(response).to have_http_status(200)
        expect(assigns(:secret)).to be_nil
      end

      it "redirects for another user's application" do
        get :show, params: { id: create(:oauth_application).id }
        expect(response).to redirect_to(oauth_clients_path)
        expect(flash[:error]).to eq("Application could not be found.")
      end
    end

    describe "GET new" do
      it "succeeds" do
        get :new
        expect(response).to have_http_status(200)
      end
    end

    describe "POST create" do
      let(:params) { { name: 'Reader', redirect_uri: 'https://reader.example.com/cb', confidential: '1' } }

      it "registers the application and shows its secret once" do
        expect { post :create, params: { application: params } }.to change { user.oauth_applications.count }.by(1)
        created = user.oauth_applications.ordered_by(:id).last
        aggregate_failures do
          expect(response).to render_template(:show)
          expect(created.name).to eq('Reader')
          expect(created.secret).not_to eq(assigns(:secret))
          expect(created.secret_matches?(assigns(:secret))).to be(true)
        end
      end

      it "rejects an insecure redirect URI" do
        expect {
          post :create, params: { application: params.merge(redirect_uri: 'http://reader.example.com/cb') }
        }.not_to change { Doorkeeper::Application.count }
        expect(response).to have_http_status(422)
        expect(flash.now[:error][:array]).to be_present
      end

      it "allows http for localhost" do
        post :create, params: { application: params.merge(redirect_uri: 'http://localhost:3000/cb') }
        expect(response).to render_template(:show)
      end
    end

    describe "PATCH update" do
      it "updates the application" do
        patch :update, params: { id: application.id, application: { name: 'Renamed' } }
        expect(response).to redirect_to(oauth_client_path(application))
        expect(application.reload.name).to eq('Renamed')
      end

      it "renders edit on failure" do
        patch :update, params: { id: application.id, application: { name: '' } }
        expect(response).to render_template(:edit)
        expect(application.reload.name).not_to eq('')
      end
    end

    describe "PATCH renew_secret" do
      it "replaces the secret" do
        old_secret = application.secret
        patch :renew_secret, params: { id: application.id }
        expect(response).to render_template(:show)
        expect(application.reload.secret).not_to eq(old_secret)
        expect(application.secret_matches?(assigns(:secret))).to be(true)
      end
    end

    describe "DELETE destroy" do
      it "deletes the application and its tokens" do
        token = Doorkeeper::AccessToken.create!(application: application, resource_owner_id: create(:user).id)
        delete :destroy, params: { id: application.id }
        expect(response).to redirect_to(oauth_clients_path)
        expect(Doorkeeper::Application.exists?(application.id)).to be(false)
        expect(Doorkeeper::AccessToken.exists?(token.id)).to be(false)
      end

      it "does not delete another user's application" do
        other = create(:oauth_application)
        delete :destroy, params: { id: other.id }
        expect(Doorkeeper::Application.exists?(other.id)).to be(true)
      end
    end
  end
end
