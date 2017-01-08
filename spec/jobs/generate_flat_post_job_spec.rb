require "spec_helper"

RSpec.describe GenerateFlatPostJob do
  it "does nothing with invalid post id" do
    expect($redis).not_to receive(:set)
    GenerateFlatPostJob.perform(-1)
  end

  it "sets redis key and quits if lock present" do
    post = create(:post)
    expect_any_instance_of(ActionView::Base).not_to receive(:render)
    $redis.set(GenerateFlatPostJob.lock_key(post.id), true)
    GenerateFlatPostJob.perform(post.id)
    expect($redis.get(GenerateFlatPostJob.lock_key(post.id))).to be_true
  end

  it "regenerates content" do
    post = create(:post)
    expect(post.flat_post.content).to be_nil

    GenerateFlatPostJob.perform(post.id)

    expect(post.flat_post.reload.content).not_to be_nil
    expect($redis.get(GenerateFlatPostJob.lock_key(post.id))).to be_nil
  end

  it "unsets key even if exception is raised" do
    post = create(:post)

    expect_any_instance_of(FlatPost).to receive(:save).and_raise(Exception)
    ResqueSpec.reset!
    Resque.enqueue(GenerateFlatPostJob, post.id)

    begin
      ResqueSpec.perform_next(GenerateFlatPostJob.queue)
    rescue Exception
    end

    expect(GenerateFlatPostJob).to have_queued(post.id).in(:high)
    expect($redis.get(GenerateFlatPostJob.lock_key(post.id))).to be_nil
  end

  it "retries if the retry key is set" do
    post = create(:post)
    key = GenerateFlatPostJob.retry_key(post.id)
    $redis.set(key, true)

    GenerateFlatPostJob.perform(post.id)

    expect(post.flat_post.reload.content).not_to be_nil
    expect($redis.get(key)).to be_nil
    expect(GenerateFlatPostJob).to have_queued(post.id).in(:high)
  end
end
