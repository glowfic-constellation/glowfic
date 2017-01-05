require "spec_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "#post_has_new_reply" do
    it "sends email" do
      ActionMailer::Base.deliveries.clear
      UserMailer.post_has_new_reply(create(:user).id, create(:reply).id).deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end

  describe "#password_reset_link" do
    it "sends email" do
      ActionMailer::Base.deliveries.clear
      UserMailer.password_reset_link(create(:password_reset).id).deliver!
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end
  end
end
