RSpec.describe SessionsController do
  describe "GET index" do
    it "works when logged out" do
      get :index
      expect(response.status).to eq(200)
      expect(controller.gon.logged_in).not_to eq(true)
    end

    it "works when logged in" do
      login
      get :index
      expect(response).to have_http_status(200)
      expect(controller.gon.logged_in).to eq(true)
    end

    it "does not show TOS prompt" do
      user = create(:user, tos_version: nil)
      login_as(user)
      get :index
      expect(response).not_to render_template('about/accept_tos')
    end

    it "logs out if user has become invalid" do
      user = create(:user)
      login_as(user)
      user.destroy!
      get :index
      expect(controller.send(:logged_in?)).not_to eq(true)
    end

    context "with render_views" do
      render_views

      it "works without link" do
        allow(ENV).to receive(:fetch).with('DISCORD_LINK_GLOWFIC', nil).and_return(nil)
        get :index
        expect(response).to have_http_status(200)
        expect(response.body).not_to include('Glowfic Community Discord')
        expect(controller.gon.logged_in).not_to eq(true)
      end

      it "works when logged out" do
        allow(ENV).to receive(:fetch).with('DISCORD_LINK_GLOWFIC', nil).and_return('https://discord.gg/fakeinvite')
        get :index
        expect(response).to have_http_status(200)
        expect(response.body).to include('Glowfic Community Discord')
        expect(response.body).to include('discord.gg')
        expect(controller.gon.logged_in).not_to eq(true)
      end

      it "works when logged in" do
        allow(ENV).to receive(:fetch).with('DISCORD_LINK_GLOWFIC', nil).and_return('https://discord.gg/fakeinvite')
        login
        get :index
        expect(response).to have_http_status(200)
        expect(response.body).to include('Glowfic Community Discord')
        expect(response.body).to include('discord.gg')
        expect(controller.gon.logged_in).to eq(true)
      end
    end
  end

  describe "PATCH confirm_tos" do
    it "redirects when logged in" do
      login
      patch :confirm_tos
      expect(response).to redirect_to(continuities_url)
      expect(flash[:error]).to eq("You are already logged in.")
    end

    it "creates cookie" do
      expect(cookies[:accepted_tos]).to be_nil
      patch :confirm_tos
      expect(response).to redirect_to(root_url)
      expect(cookies[:accepted_tos].to_i).to eq(User::CURRENT_TOS_VERSION)
    end
  end
end
