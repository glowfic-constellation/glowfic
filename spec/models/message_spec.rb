require "spec_helper"

RSpec.describe Message do
  describe "#notify_recipient" do
    before(:each) do ResqueSpec.reset! end

    it "sends" do
      message = create(:message)
      expect(message.recipient.email_notifications).not_to be_true

      user = create(:user)
      user.update_attribute('email', nil)
      create(:message, recipient: user)

      notified_user = create(:user, email_notifications: true)
      message = create(:message, recipient: notified_user)

      expect(UserMailer).to have_queue_size_of(1)
      expect(UserMailer).to have_queued(:new_message, [message.id])
    end
  end
end
