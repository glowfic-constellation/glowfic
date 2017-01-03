require "spec_helper"

RSpec.describe EmailPostHasNewReplyJob do
  it "does nothing with invalid user id" do
    reply = create(:reply)

    ActionMailer::Base.deliveries.clear
    EmailPostHasNewReplyJob.perform(-1, reply.id)
    expect(ActionMailer::Base.deliveries.count).to eq(0)
  end

  it "does nothing with invalid reply id" do
    user = create(:user, email_notifications: true)

    ActionMailer::Base.deliveries.clear
    EmailPostHasNewReplyJob.perform(user.id, -1)
    expect(ActionMailer::Base.deliveries.count).to eq(0)
  end

  it "does nothing without email" do
    user = create(:user, email_notifications: true)
    user.update_attribute(:email, nil)
    reply = create(:reply)

    ActionMailer::Base.deliveries.clear
    EmailPostHasNewReplyJob.perform(user.id, reply.id)
    expect(ActionMailer::Base.deliveries.count).to eq(0)
  end

  it "does nothing without notifications on" do
    user = create(:user, email_notifications: false)
    reply = create(:reply)

    ActionMailer::Base.deliveries.clear
    EmailPostHasNewReplyJob.perform(user.id, reply.id)
    expect(ActionMailer::Base.deliveries.count).to eq(0)
  end

  it "sends email" do
    user = create(:user, email_notifications: true)
    reply = create(:reply)

    ActionMailer::Base.deliveries.clear
    EmailPostHasNewReplyJob.perform(user.id, reply.id)
    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end
end
