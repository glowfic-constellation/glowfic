require "spec_helper"

RSpec.describe Post do
  describe "#edited_at" do
    it "should update when a field is changed" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      post.content = 'new content now'
      post.save
      expect(post.edited_at).not_to eq(post.created_at)
    end

    it "should update when multiple fields are changed" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      post.content = 'new content now'
      post.description = 'description'
      post.save
      expect(post.edited_at).not_to eq(post.created_at)
    end

    it "should not update when skip is set" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      post.skip_edited = true
      post.touch
      expect(post.edited_at).to eq(post.created_at)
    end

    it "should not update when a reply is made" do
      post = create(:post)
      expect(post.edited_at).to eq(post.created_at)
      create(:reply, post: post, user: post.user)
      expect(post.edited_at).to eq(post.created_at)
    end
  end
end
