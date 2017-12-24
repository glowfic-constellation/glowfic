require "spec_helper"

RSpec.describe UpdateModelJob do
  before(:each) { ResqueSpec.reset! }

  it "crashes on invalid models" do
    expect {
      UpdateModelJob.perform_now('NotClass', {}, {})
    }.to raise_error(NameError)
  end

  it "crashes on invalid wheres" do
    expect {
      UpdateModelJob.perform_now('Reply', {board_id: 2}, {})
    }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "crashes on invalid attrs" do
    reply = create(:reply)
    expect {
      UpdateModelJob.perform_now('Reply', {id: reply.id}, {board_id: 2})
    }.to raise_error(ActiveModel::UnknownAttributeError)
  end
end
