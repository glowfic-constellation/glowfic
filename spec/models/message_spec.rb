require "spec_helper"

RSpec.describe Message do
  describe "#notify_recipient" do
    before(:each) do ResqueSpec.reset! end

    it "sends" do
      message = create(:message)
      expect(message.recipient.email_notifications).not_to eq(true)

      user = create(:user)
      user.update_columns(email: nil)
      create(:message, recipient: user)

      notified_user = create(:user, email_notifications: true)
      message = create(:message, recipient: notified_user)

      expect(UserMailer).to have_queue_size_of(1)
      expect(UserMailer).to have_queued(:new_message, [message.id])
    end

    it "cannot have a nil sender" do
      message = build(:message)
      message.sender = nil
      expect(message).not_to be_valid
    end

    it "can have a zero sender_id to represent site messages" do
      message = build(:message)
      message.sender_id = 0
      expect(message).to be_valid
      expect(message.sender_name).to eq('Glowfic Constellation')
    end

    it "does not notify blocking recipients" do
      sender = create(:user)
      recipient = create(:user)
      create(:block, blocking_user: recipient, blocked_user: sender, block_interactions: true)
      message = create(:message, sender: sender, recipient: recipient)
      expect(message.visible_inbox).to eq(false)
      expect(UserMailer).to have_queue_size_of(0)
    end
  end

  it "validates recipient" do
    sender = create(:user)
    recipient = create(:user)
    create(:block, blocking_user: recipient, blocked_user: sender, block_interactions: true)
    message = build(:message, sender: sender, recipient: recipient)
    expect(message).to be_valid
    message.save!
    expect(message.visible_inbox).to eq(false)
  end
end
