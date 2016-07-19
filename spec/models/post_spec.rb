require "spec_helper"

RSpec.describe Post do
  it "should have the right timestamps" do
    # creation
    post = create(:post)
    expect(post.edited_at).to eq(post.created_at)
    expect(post.tagged_at).to eq(post.created_at)

    # edited with no replies
    post.content = 'new content'
    post.save
    expect(post.tagged_at).to eq(post.edited_at)
    expect(post.tagged_at).to be > post.created_at
    old_edited_at = post.edited_at

    # reply created
    reply = create(:reply, post: post)
    post.reload
    expect(post.tagged_at).to eq(reply.created_at)
    expect(post.edited_at).to eq(old_edited_at)
    expect(post.tagged_at).to be > post.edited_at
    old_tagged_at = post.tagged_at

    # edited with replies
    post.content = 'newer content'
    post.save
    expect(post.tagged_at).to eq(old_tagged_at)
    expect(post.edited_at).to be > old_edited_at

    # second reply created
    reply2 = create(:reply, post: post)
    post.reload
    expect(post.tagged_at).to eq(reply2.created_at)
    expect(post.updated_at).to be >= reply2.created_at
    expect(post.tagged_at).to be > post.edited_at
    old_tagged_at = post.tagged_at
    old_edited_at = post.edited_at

    # first reply updated
    reply.content = 'new content'
    reply.skip_post_update = true unless reply.post.last_reply_id == reply.id
    reply.save
    post.reload
    expect(post.tagged_at).to eq(old_tagged_at) # BAD
    expect(post.edited_at).to eq(old_edited_at)

    # second reply updated
    reply2.content = 'new content'
    reply2.skip_post_update = true unless reply2.post.last_reply_id == reply2.id
    reply2.save
    post.reload
    expect(post.tagged_at).to eq(reply2.updated_at)
    expect(post.edited_at).to eq(old_edited_at)
  end

  it "should allow blank content" do
    post = create(:post, content: nil)
    expect(post.id).not_to be_nil
  end

  describe "#destroy" do
    it "should delete views" do
      post = create(:post)
      user = create(:user)
      expect(PostView.count).to be_zero
      post.mark_read(user)
      expect(PostView.count).not_to be_zero
      post.destroy
      expect(PostView.count).to be_zero
    end
  end

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
