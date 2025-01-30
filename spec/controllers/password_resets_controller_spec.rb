RSpec.describe PasswordResetsController do
  include ActionMailer::TestHelper

  describe "GET new" do
    it "requires logout" do
      user = create(:user)
      login_as(user)
      get :new
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:error]).to eq("You are already logged in.")
    end

    it "succeeds when logged out" do
      get :new
      expect(response.status).to eq(200)
    end
  end

  describe "POST create" do
    it "requires logout" do
      user = create(:user)
      login_as(user)
      post :create
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:error]).to eq("You are already logged in.")
    end

    it "requires username" do
      post :create, params: { email: 'fake_email' }
      expect(response).to render_template('new')
      expect(flash[:error]).to eq("Username is required.")
    end

    it "requires email" do
      post :create, params: { username: 'fake_username' }
      expect(response).to render_template('new')
      expect(flash[:error]).to eq("Email is required.")
    end

    it "handles user not found" do
      post :create, params: { username: 'fake_username', email: 'fake_email' }
      expect(response).to render_template('new')
      expect(flash[:error]).to eq("Account could not be found.")
    end

    it "handles email match but not username" do
      user = create(:user)
      post :create, params: { username: 'fake_username', email: user.email }
      expect(response).to render_template('new')
      expect(flash[:error]).to eq("Account could not be found.")
    end

    it "handles username match but not email" do
      user = create(:user)
      post :create, params: { username: user.username, email: 'fake_email' }
      expect(response).to render_template('new')
      expect(flash[:error]).to eq("Account could not be found.")
    end

    it "handles failed save" do
      user = create(:user)
      reset = PasswordReset.new
      allow(PasswordReset).to receive(:new) do |args|
        reset.assign_attributes(args)
        reset
      end
      allow(reset).to receive(:generate_auth_token).and_return(nil)
      expect(reset).to receive(:generate_auth_token)
      post :create, params: { username: user.username, email: user.email }
      expect(response).to render_template('new')
      expect(flash[:error][:message]).to eq("Password reset could not be created because of the following problems:")
      expect(flash[:error][:array]).to eq(["Auth token can't be blank"])
    end

    it "resends link if reset already present" do
      ActionMailer::Base.deliveries.clear
      user = create(:user)
      reset = create(:password_reset, user: user)
      expect(PasswordReset.count).to eq(1)
      expect {
        post :create, params: { username: user.username, email: user.email }
      }.to have_enqueued_email(UserMailer, :password_reset_link).with(reset.id)
      expect(flash[:success]).to eq("Your password reset link has been re-sent.")
      expect(PasswordReset.count).to eq(1)
    end

    it "sends password reset" do
      ActionMailer::Base.deliveries.clear
      user = create(:user)
      clear_enqueued_jobs
      expect {
        post :create, params: { username: user.username, email: user.email }
      }.to have_enqueued_email(UserMailer, :password_reset_link)
      assert_enqueued_email_with(UserMailer, :password_reset_link, args: [PasswordReset.first.id])
      expect(response).to redirect_to(new_password_reset_url)
      expect(flash[:success]).to eq("A password reset link has been emailed to you.")
      expect(PasswordReset.count).to eq(1)
      expect(PasswordReset.first.user_id).to eq(user.id)
    end
  end

  describe "GET show" do
    it "requires logout" do
      user = create(:user)
      login_as(user)
      get :show, params: { id: -1 }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:error]).to eq("You are already logged in.")
    end

    it "requires valid token" do
      get :show, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("Authentication token not found.")
    end

    it "requires active token" do
      token = create(:expired_password_reset)
      get :show, params: { id: token.auth_token }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("Authentication token expired.")
    end

    it "requires unused token" do
      token = create(:used_password_reset)
      get :show, params: { id: token.auth_token }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("Authentication token has already been used.")
    end

    it "succeeds" do
      token = create(:password_reset)
      get :show, params: { id: token.auth_token }
      expect(response.status).to eq(200)
    end
  end

  describe "PUT update" do
    it "requires logout" do
      user = create(:user)
      login_as(user)
      put :update, params: { id: -1 }
      expect(response).to redirect_to(edit_user_url(user))
      expect(flash[:error]).to eq("You are already logged in.")
    end

    it "requires valid token" do
      put :update, params: { id: -1 }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("Authentication token not found.")
    end

    it "requires active token" do
      token = create(:expired_password_reset)
      put :update, params: { id: token.auth_token }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("Authentication token expired.")
    end

    it "requires unused token" do
      token = create(:used_password_reset)
      put :update, params: { id: token.auth_token }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("Authentication token has already been used.")
    end

    it "requires password" do
      token = create(:password_reset)
      put :update, params: { id: token.auth_token, password_confirmation: 'newpass' }
      expect(flash[:error][:message]).to eq("Password could not be updated because of the following problems:")
      expect(response).to render_template('show')
    end

    it "requires long enough password" do
      token = create(:password_reset)
      put :update, params: { id: token.auth_token, password: 'new', password_confirmation: 'new' }
      expect(flash[:error][:message]).to eq("Password could not be updated because of the following problems:")
      expect(response).to render_template('show')
    end

    it "requires password confirmation" do
      token = create(:password_reset)
      put :update, params: { id: token.auth_token, password: 'newpass' }
      expect(flash[:error][:message]).to eq("Password could not be updated because of the following problems:")
      expect(response).to render_template('show')
    end

    it "requires password and confirmation to match" do
      token = create(:password_reset)
      put :update, params: { id: token.auth_token, password: 'newpass', password_confirmation: 'notnewpass' }
      expect(flash[:error][:message]).to eq("Password could not be updated because of the following problems:")
      expect(response).to render_template('show')
    end

    it "succeeds" do
      token = create(:password_reset)
      expect(token.user.authenticate('newpass')).to eq(false)
      put :update, params: { id: token.auth_token, password: 'newpass', password_confirmation: 'newpass' }
      expect(response).to redirect_to(root_url)
      expect(flash[:success]).to eq("Password changed.")
      expect(token.reload).to be_used
      expect(token.user.authenticate('newpass')).to eq(true)
    end
  end
end
