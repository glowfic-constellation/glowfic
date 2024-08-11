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

  describe "#check_read" do
    let(:post) { create(:post) }
    let(:user) { create(:user) }
    let(:notification) { create(:notification, user: user, post: post) }

    it "does nothing without a post" do
      notification = create(:error_notification)
      expect(notification.unread).to eq(true)
      expect(notification.read_at).to eq(nil)
    end

    it "does nothing without a post view" do
      notification
      expect(notification.unread).to eq(true)
      expect(notification.read_at).to eq(nil)
    end

    it "does nothing without a read_at" do
      post.ignore(user)
      notification
      expect(notification.unread).to eq(true)
      expect(notification.read_at).to eq(nil)
    end

    it "marks notification read with read_at" do
      time = 10.minutes.ago
      post.mark_read(user, at_time: time)
      notification
      expect(notification.unread).to eq(false)
      expect(notification.read_at).to be_the_same_time_as(time)
    end
  end
end
