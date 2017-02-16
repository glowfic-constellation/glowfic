require "spec_helper"

RSpec.describe UserMailer, type: :mailer do
  before { ResqueSpec.reset! }
  describe "#post_has_new_reply" do
    it "sends email" do
      ActionMailer::Base.deliveries.clear
      UserMailer.post_has_new_reply(create(:user).id, create(:reply).id).deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it "does not crash on deleted reply" do
      reply = create(:reply)

      ActionMailer::Base.deliveries.clear
      UserMailer.post_has_new_reply(create(:user).id, reply.id).deliver
      expect(UserMailer).to have_queue_size_of(1)

      reply.destroy
      ResqueSpec.perform_next(UserMailer.queue)
      expect(UserMailer).to have_queue_size_of(0)
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end
  end

  describe "#password_reset_link" do
    it "sends email" do
      ActionMailer::Base.deliveries.clear
      UserMailer.password_reset_link(create(:password_reset).id).deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end

  describe "#new_message" do
    it "sends email" do
      ActionMailer::Base.deliveries.clear
      UserMailer.new_message(create(:message).id).deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end
end
