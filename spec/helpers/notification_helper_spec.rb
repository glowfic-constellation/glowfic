RSpec.describe NotificationHelper do
  describe "#subject_for_type" do
    it "has a subject for every notification type" do
      missing = Notification.notification_types.keys.reject { |type| subject_for_type(type) }
      expect(missing).to be_empty
    end
  end
end
