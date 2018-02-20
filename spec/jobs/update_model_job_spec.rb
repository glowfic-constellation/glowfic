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

  it "does not update tagged_at" do
    reply = create(:reply)
    old_tag = reply.post.tagged_at
    new_char = create(:character, user: reply.user)
    expect(reply.character).to be_nil
    UpdateModelJob.perform_now('Reply', {id: reply.id}, {character_id: new_char.id})
    expect(reply.reload.character).to eq(new_char)
    expect(reply.post.reload.tagged_at).to be_the_same_time_as(old_tag)
  end
end
