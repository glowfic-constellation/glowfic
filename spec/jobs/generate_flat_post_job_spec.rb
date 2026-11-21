RSpec.describe GenerateFlatPostJob do
  include ActiveJob::TestHelper

  before(:each) { clear_enqueued_jobs }

  describe ".enqueue" do
    it "enqueues post when there's no lock" do
      $redis.del("lock.generate_flat_posts.0")

      expect {
        GenerateFlatPostJob.enqueue(0)
      }.to have_enqueued_job.with(0)
      expect($redis.get("lock.generate_flat_posts.0")).to eq("true")
    end

    it "does not enqueue post if already locked" do
      $redis.set("lock.generate_flat_posts.0", true)
      expect {
        GenerateFlatPostJob.enqueue(0)
      }.not_to have_enqueued_job
    end
  end

  describe "#perform" do
    it "does nothing with invalid post id" do
      expect($redis).not_to receive(:set)
      GenerateFlatPostJob.perform_now(-1)
    end

    it "quits if lock present" do
      post = create(:post)
      $redis.set(GenerateFlatPostJob.lock_key(post.id), true)
      expect {
        create(:reply, post: post)
      }.not_to have_enqueued_job(GenerateFlatPostJob)
    end

    it "deletes key when retry gives up" do
      exc = StandardError.new
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

    it "unsets key even if error is raised" do
      post = create(:post)
      flat = post.flat_post
      $redis.set(GenerateFlatPostJob.lock_key(post.id), true)

      exc = StandardError

      allow(Post).to receive(:find_by).and_call_original
      allow(Post).to receive(:find_by).with({ id: post.id }).and_return(post)
      allow(post).to receive(:flat_post).and_return(flat)
      allow(flat).to receive(:save!).and_raise(exc)
      expect(flat).to receive(:save!)
      expect(ApplicationJob).to receive(:notify_exception).with(exc, post.id).and_call_original
      clear_enqueued_jobs

      begin
        GenerateFlatPostJob.perform_now(post.id)
      rescue StandardError
      else
        raise "Error should be handled"
      end

      expect($redis.get(GenerateFlatPostJob.lock_key(post.id))).to be_nil
    end

    it "retries if resque is terminated" do
      post = create(:post)
      flat = post.flat_post
      $redis.set(GenerateFlatPostJob.lock_key(post.id), true)
      exc = Resque::TermException.new("SIGTERM")

      allow(Post).to receive(:find_by).and_call_original
      allow(Post).to receive(:find_by).with({ id: post.id }).and_return(post)
      allow(post).to receive(:flat_post).and_return(flat)
      allow(flat).to receive(:save!).and_raise(exc)
      expect(flat).to receive(:save!)
      clear_enqueued_jobs

      job = GenerateFlatPostJob.new(post.id)
      expect(job).to receive(:retry_job)
      job.perform_now
    end

    it "lets a reply saved while rendering enqueue a new run" do
      post = create(:post)
      clear_enqueued_jobs
      $redis.set(GenerateFlatPostJob.lock_key(post.id), true)
      allow(PostsController).to receive(:render).and_wrap_original do |original, *args, **kwargs|
        GenerateFlatPostJob.enqueue(post.id) # a reply is saved here
        original.call(*args, **kwargs)
      end

      expect { GenerateFlatPostJob.perform_now(post.id) }.to have_enqueued_job(GenerateFlatPostJob).with(post.id)
    end

    it "releases the lock even if the post no longer exists" do
      $redis.set(GenerateFlatPostJob.lock_key(-1), true)
      GenerateFlatPostJob.perform_now(-1)
      expect($redis.get(GenerateFlatPostJob.lock_key(-1))).to be_nil
    end

    it "builds a FlatPost object if one does not exist" do
      post = create(:post)
      expect(post.flat_post).not_to be_nil
      post.flat_post.destroy!

      GenerateFlatPostJob.perform_now(post.id)
      expect(FlatPost.find_by(post: post)).not_to be_nil
    end

    context "with another worker rendering the same post" do
      let(:post) { create(:post) }

      before(:each) do
        $redis.del(GenerateFlatPostJob.lock_key(post.id), GenerateFlatPostJob.running_key(post.id), GenerateFlatPostJob.dirty_key(post.id))
      end

      it "does not render, and marks the post dirty" do
        $redis.set(GenerateFlatPostJob.running_key(post.id), true)

        expect { GenerateFlatPostJob.perform_now(post.id) }.not_to have_enqueued_job(GenerateFlatPostJob)

        expect(post.flat_post.reload.content).to be_nil
        expect($redis.get(GenerateFlatPostJob.dirty_key(post.id))).to eq("true")
        expect($redis.get(GenerateFlatPostJob.running_key(post.id))).to eq("true") # not released by the loser
      end

      it "runs again after finishing if the post was marked dirty meanwhile" do
        $redis.set(GenerateFlatPostJob.dirty_key(post.id), true)

        expect { GenerateFlatPostJob.perform_now(post.id) }.to have_enqueued_job(GenerateFlatPostJob).with(post.id)

        expect($redis.get(GenerateFlatPostJob.dirty_key(post.id))).to be_nil
        expect($redis.get(GenerateFlatPostJob.running_key(post.id))).to be_nil
      end

      it "releases the running lock when rendering fails" do
        allow(PostsController).to receive(:render).and_raise(StandardError)

        expect { GenerateFlatPostJob.perform_now(post.id) }.to raise_error(StandardError)

        expect($redis.get(GenerateFlatPostJob.running_key(post.id))).to be_nil
      end
    end
  end
end
