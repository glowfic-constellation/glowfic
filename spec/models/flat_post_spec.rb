require "spec_helper"

RSpec.describe FlatPost do
  include ActiveJob::TestHelper

  describe ".regenerate_all" do
    def delete_lock(post)
      lock_key = GenerateFlatPostJob.lock_key(post.id)
      $redis.del(lock_key)
    end

    it "regenerates all flat posts" do
      post = create(:post)
      delete_lock(post)
      FlatPost.regenerate_all
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
    end

    it "regenerates only old flat posts with argument" do
      post = create(:post)
      nonpost = Timecop.freeze(post.tagged_at + 2.hours) { create(:post) }
      delete_lock(post)
      delete_lock(nonpost)
      FlatPost.regenerate_all(post.tagged_at + 1.hours)
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
      expect(GenerateFlatPostJob).not_to have_been_enqueued.with(nonpost.id).on_queue('high')
    end

    it "regenerates only matching flat posts with arguments" do
      post = create(:post)
      nonpost = create(:post)

      reply = build(:reply, post: post)
      reply.skip_regenerate = true
      reply.save!

      delete_lock(post)
      delete_lock(nonpost)
      FlatPost.regenerate_all(nil, false)
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
      expect(GenerateFlatPostJob).not_to have_been_enqueued.with(nonpost.id).on_queue('high')
    end

    it "handles missing flat posts" do
      post = create(:post)
      post.flat_post.delete
      delete_lock(post)
      FlatPost.regenerate_all
      expect(GenerateFlatPostJob).to have_been_enqueued.with(post.id).on_queue('high')
    end
  end
end
