RSpec.describe Notification do
  describe "validations" do
    it "cannot have a nil user" do
      notification = build(:notification, user: nil)
      expect(notification).not_to be_valid
    end

    it "must have a valid type" do
      expect { build(:notification, notification_type: :foo) }.to raise_error(ArgumentError)
    end

    it "can have a nil post" do
      notification = build(:notification, post: nil)
      expect(notification).to be_valid
    end
  end

  describe "#notify_recipient" do
    let!(:user) { create(:user, email_notifications: true) }
    let!(:notification) { build(:notification, user: user) }

    before(:each) { ResqueSpec.reset! }

    it "does not send with notifications off" do
      user.update!(email_notifications: false)
      notification.save!
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "does not send with no email" do
      user.update_columns(email: nil) # rubocop:disable Rails/SkipsModelValidations
      notification.save!
      expect(UserMailer).to have_queue_size_of(0)
    end

    it "sends with notifications on" do
      notification.save!
      expect(UserMailer).to have_queue_size_of(1)
      expect(UserMailer).to have_queued(:new_notification, [notification.id])
    end
  end
end
