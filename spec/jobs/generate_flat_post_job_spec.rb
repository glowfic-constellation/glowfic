require "spec_helper"

RSpec.describe GenerateFlatPostJob do
  include ActiveJob::TestHelper
  before(:each) { clear_enqueued_jobs }
  it "does nothing with invalid post id" do
    expect($redis).not_to receive(:set)
    GenerateFlatPostJob.perform_now(-1)
  end

  it "quits if lock present" do
    post = create(:post)
    $redis.set(GenerateFlatPostJob.lock_key(post.id), true)
    create(:reply)
    expect(GenerateFlatPostJob).not_to have_queued(post.id).in(:high)
  end

  it "deletes key when retry gives up" do
    exc = Exception.new
    $redis.set(GenerateFlatPostJob.lock_key(2), true)
    GenerateFlatPostJob.notify_exception(exc, 2)
    expect($redis.get(GenerateFlatPostJob.lock_key(2))).to be_nil
  end

  it "regenerates content" do
    post = create(:post)
    expect(post.flat_post.content).to be_nil

    GenerateFlatPostJob.perform_now(post.id)

    expect(post.flat_post.reload.content).not_to be_nil
    expect($redis.get(GenerateFlatPostJob.lock_key(post.id))).to be_nil
  end

  it "unsets key even if exception is raised" do
    post = create(:post)
    $redis.set(GenerateFlatPostJob.lock_key(post.id), true)

    exc = Exception
    expect_any_instance_of(FlatPost).to receive(:save!).and_raise(exc)
    expect(ApplicationJob).to receive(:notify_exception).with(exc, post.id).and_call_original
    clear_enqueued_jobs

    begin
      GenerateFlatPostJob.perform_now(post.id)
    rescue Exception
    else
      raise "Error should be handled"
    end

    expect($redis.get(GenerateFlatPostJob.lock_key(post.id))).to be_nil
  end
end
