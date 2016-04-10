require "spec_helper"

RSpec.describe Post do
  describe "#edited_at" do
    it "should update when a field is changed" do
      now = Time.now
      post = nil

      Timecop.freeze(now) do
        post = create(:post)
        expect(post.edited_at).to eq(post.created_at)
      end

      Timecop.freeze(now + 1.day) do
        post.content = 'new content now'
        post.save
        expect(post.edited_at).not_to eq(post.created_at)
      end
    end

    it "should update when multiple fields are changed" do
      now = Time.now
      post = nil

      Timecop.freeze(now) do
        post = create(:post)
        expect(post.edited_at).to eq(post.created_at)
      end

      Timecop.freeze(now + 1.day) do
        post.content = 'new content now'
        post.description = 'description'
        post.save
        expect(post.edited_at).not_to eq(post.created_at)
      end
    end

    it "should not update when only updated_at is changed" do
      now = Time.now
      post = nil

      Timecop.freeze(now) do
        post = create(:post)
        expect(post.edited_at).to eq(post.created_at)
      end

      Timecop.freeze(now + 1.day) do
        post.touch
        expect(post.edited_at).to eq(post.created_at)
      end
    end

    it "should not update when a reply is made" do
      now = Time.now
      post = nil

      Timecop.freeze(now) do
        post = create(:post)
        expect(post.edited_at).to eq(post.created_at)
      end

      Timecop.freeze(now + 1.day) do
        create(:reply, post: post, user: post.user)
        expect(post.edited_at).to eq(post.created_at)
      end
    end
  end
end
