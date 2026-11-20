# frozen_string_literal: true
RSpec.describe UsersController, '#update' do
  include ActiveJob::TestHelper

  let(:user) { create(:user, password: 'oldpassword1') }

  before(:each) { login_as(user) }

  it "does not let #update change the password without the old password" do
    put :update, params: { id: user.id, user: { password: 'x', password_confirmation: 'x' } }
    expect(user.reload.authenticate('oldpassword1')).to eq(true)
  end

  context "when changing the email address" do
    it "requires the current password" do
      old_email = user.email
      expect {
        put :update, params: { id: user.id, user: { email: 'new@example.com' } }
      }.not_to have_enqueued_mail
      expect(response).to render_template(:edit)
      expect(flash[:error]).to eq('Incorrect password entered.')
      expect(user.reload.email).to eq(old_email)
    end

    it "rejects a wrong password" do
      old_email = user.email
      put :update, params: { id: user.id, old_password: 'wrong', user: { email: 'new@example.com' } }
      expect(response).to render_template(:edit)
      expect(user.reload.email).to eq(old_email)
    end

    it "changes the email and notifies the old address with the right password" do
      old_email = user.email
      expect {
        put :update, params: { id: user.id, old_password: 'oldpassword1', user: { email: 'new@example.com' } }
      }.to have_enqueued_mail(UserMailer, :email_changed).with(user.id, old_email)
      expect(response).to redirect_to(edit_user_url(user))
      expect(user.reload.email).to eq('new@example.com')
    end

    it "does not ask for the password or send mail when the email is unchanged" do
      expect {
        put :update, params: { id: user.id, user: { email: user.email, email_notifications: true } }
      }.not_to have_enqueued_mail
      expect(flash[:success]).to eq('Changes saved.')
    end
  end
end
