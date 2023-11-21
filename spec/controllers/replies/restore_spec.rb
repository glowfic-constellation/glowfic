RSpec.describe RepliesController, 'POST restore' do
  before(:each) { Reply.auditing_enabled = true }

  after(:each) { Reply.auditing_enabled = false }

  it "requires login" do
    post :restore, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create replies"
  end

  it "must find the reply" do
    expect(Reply.find_by(id: 99)).to be_nil
    expect(Audited::Audit.find_by(auditable_id: 99)).to be_nil
    login
    post :restore, params: { id: 99 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Reply could not be found.")
  end

  it "must be a deleted reply" do
    reply = create(:reply)
    Audited::Audit.where(action: 'create').find_by(auditable_id: reply.id).update!(action: 'destroy')
    login_as(reply.user)
    post :restore, params: { id: 99 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Reply could not be found.")
  end

  it "must be your reply" do
    rpost = create(:post)
    reply = create(:reply, post: rpost)
    login_as(rpost.user)
    reply.destroy!
    post :restore, params: { id: reply.id }
    expect(response).to redirect_to(post_url(rpost))
    expect(flash[:error]).to eq('You do not have permission to modify this reply.')
  end

  it "handles mid reply deletion" do
    rpost = create(:post)
    replies = create_list(:reply, 4, post: rpost, user: rpost.user)
    deleted_reply = replies[2]
    deleted_reply.destroy!
    Timecop.freeze(rpost.reload.tagged_at + 1.day) { create(:reply, post: rpost, user: rpost.user) }
    post_attributes = Post.find_by(id: rpost.id).attributes

    login_as(rpost.user)
    post :restore, params: { id: deleted_reply.id }

    expect(Reply.find_by(id: deleted_reply.id)).to eq(deleted_reply)
    reloaded_post = Post.find_by(id: rpost.id)
    new_attributes = reloaded_post.attributes
    post_attributes.each do |key, val|
      expect(new_attributes[key]).to eq(val)
    end
    expect(reloaded_post.replies.pluck(:reply_order).sort).to eq(0.upto(4).to_a)
  end

  it "handles first reply deletion" do
    rpost = create(:post)
    replies = create_list(:reply, 2, post: rpost, user: rpost.user)
    deleted_reply = replies.first
    deleted_reply.destroy!
    Timecop.freeze(rpost.reload.tagged_at + 1.day) { create(:reply, post: rpost, user: rpost.user) }
    post_attributes = Post.find_by(id: rpost.id).attributes

    login_as(rpost.user)
    post :restore, params: { id: deleted_reply.id }

    expect(Reply.find_by(id: deleted_reply.id)).to eq(deleted_reply)
    reloaded_post = Post.find_by(id: rpost.id)
    new_attributes = reloaded_post.attributes
    post_attributes.each do |key, val|
      expect(new_attributes[key]).to eq(val)
    end
    expect(reloaded_post.replies.pluck(:reply_order).sort).to eq(0.upto(2).to_a)
  end

  it "handles last reply deletion" do
    rpost = create(:post)
    create_list(:reply, 2, post: rpost, user: rpost.user)
    deleted_reply = Timecop.freeze(rpost.reload.tagged_at + 1.day) { create(:reply, post: rpost) }
    deleted_reply.destroy!
    post_attributes = Post.find_by(id: rpost.id).attributes

    login_as(deleted_reply.user)
    post :restore, params: { id: deleted_reply.id }

    expect(Reply.find_by(id: deleted_reply.id)).to eq(deleted_reply)
    reloaded_post = Post.find_by(id: rpost.id)
    new_attributes = reloaded_post.attributes
    post_attributes.each do |key, val|
      next if %w(last_reply_id last_user_id updated_at tagged_at).include?(key.to_s)
      expect(new_attributes[key]).to eq(val), "#{key}s did not match, #{new_attributes[key]} should have been #{val}"
    end
    expect(reloaded_post.last_user).to eq(deleted_reply.user)
    expect(reloaded_post.last_reply).to eq(deleted_reply)
    expect(reloaded_post.replies.pluck(:reply_order).sort).to eq(0.upto(2).to_a)
  end

  it "handles only reply deletion" do
    rpost = create(:post)
    expect(rpost.last_user).to eq(rpost.user)
    expect(rpost.last_reply).to be_nil

    deleted_reply = Timecop.freeze(rpost.reload.tagged_at + 1.day) { create(:reply, post: rpost) }
    rpost = Post.find(rpost.id)
    expect(rpost.last_user).to eq(deleted_reply.user)
    expect(rpost.last_reply).to eq(deleted_reply)

    deleted_reply.destroy!
    rpost = Post.find(rpost.id)
    expect(rpost.last_user).to eq(rpost.user)
    expect(rpost.last_reply).to be_nil

    login_as(deleted_reply.user)
    post :restore, params: { id: deleted_reply.id }
    rpost = Post.find(rpost.id)
    expect(rpost.last_user).to eq(deleted_reply.user)
    expect(rpost.last_reply).to eq(deleted_reply)
  end

  it "does not allow restoring something already restored" do
    reply = create(:reply)
    reply.destroy!
    login_as(reply.user)
    post :restore, params: { id: reply.id }
    expect(flash[:success]).to eq("Reply restored.")
    post :restore, params: { id: reply.id }
    expect(flash[:error]).to eq("Reply does not need restoring.")
    expect(response).to redirect_to(post_url(reply.post))
  end

  it "correctly restores a previously restored reply" do
    reply = Timecop.freeze(2.days.ago) { create(:reply, content: 'not yet restored') }
    original_created_at = reply.created_at
    reply.destroy!
    login_as(reply.user)

    Timecop.freeze(1.day.ago) do
      post :restore, params: { id: reply.id }
    end

    expect(flash[:success]).to eq("Reply restored.")

    reply = Reply.find(reply.id)
    expect(reply.created_at).to be_the_same_time_as(original_created_at)
    reply.update!(content: 'restored right')
    reply.destroy!

    post :restore, params: { id: reply.id }
    expect(flash[:success]).to eq("Reply restored.")
    reply = Reply.find(reply.id)
    expect(reply.created_at).to be_the_same_time_as(original_created_at)
    expect(reply.content).to eq('restored right')
  end

  it "correctly restores the reply's created_at date" do
    reply = Timecop.freeze(DateTime.now.utc - 1.day) { create(:reply) }
    old_created_at = reply.created_at
    reply.destroy!
    login_as(reply.user)
    post :restore, params: { id: reply.id }

    expect(flash[:success]).to eq("Reply restored.")
    reply = Reply.find(reply.id)
    expect(reply.created_at).to be_the_same_time_as(old_created_at)
  end

  it "does not update post status" do
    rpost = create(:post)
    reply = create(:reply, post: rpost, user: rpost.user)
    create(:reply, post: rpost, user: rpost.user)
    reply.destroy!

    rpost.update!(status: :hiatus)
    login_as(rpost.user)
    post :restore, params: { id: reply.id }
    expect(flash[:success]).to eq("Reply restored.")
    expect(Post.find(rpost.id)).to be_hiatus
  end
end
