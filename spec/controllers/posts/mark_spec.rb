RSpec.describe PostsController, 'POST mark' do
  let(:user) { create(:user) }
  let(:private_post) { create(:post, privacy: :private) }
  let(:posts) { create_list(:post, 2) }
  let(:reply_post) { create(:post) }
  let(:owed_post) { create(:post, unjoined_authors: [user]) }

  it "requires login" do
    post :mark
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  context "read" do
    before(:each) { login_as(user) }

    it "skips invisible post" do
      post :mark, params: { marked_ids: [private_post.id], commit: "Mark Read" }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("0 posts marked as read.")
      expect(private_post.reload.last_read(user)).to be_nil
    end

    it "reads posts" do
      expect(posts[0].last_read(user)).to be_nil
      expect(posts[1].last_read(user)).to be_nil

      post :mark, params: { marked_ids: posts.map { |x| x.id.to_s }, commit: "Mark Read" }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts marked as read.")
      expect(posts[0].reload.last_read(user)).not_to be_nil
      expect(posts[1].reload.last_read(user)).not_to be_nil
    end

    it "works for reader users" do
      user.update!(role_id: Permissible::READONLY)

      post :mark, params: { marked_ids: posts.map { |x| x.id.to_s }, commit: "Mark Read" }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts marked as read.")
    end
  end

  context "ignored" do
    before(:each) { login_as(user) }

    it "skips invisible post" do
      post :mark, params: { marked_ids: [private_post.id] }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("0 posts hidden from this page.")
      expect(private_post.reload.ignored_by?(user)).not_to eq(true)
    end

    it "ignores posts" do
      post :mark, params: { marked_ids: posts.map { |x| x.id.to_s } }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts hidden from this page.")
      expect(posts[0].reload.ignored_by?(user)).to eq(true)
      expect(posts[1].reload.ignored_by?(user)).to eq(true)
    end

    it "works for reader users" do
      user.update!(role_id: Permissible::READONLY)

      post :mark, params: { marked_ids: posts.map { |x| x.id.to_s } }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts hidden from this page.")
    end

    it "does not mess with read timestamps", aggregate_failures: false do
      time = 10.minutes.ago
      post1, post2, post3 = Timecop.freeze(time) { create_list(:post, 3) }

      [post1, post2, post3].each do |p|
        5.times do |i|
          Timecop.freeze(time + i.minutes) { create(:reply, post: p) }
        end
        p.reload
      end

      time2 = post2.replies.first.updated_at
      time3 = post3.replies.last.updated_at
      post2.mark_read(user, at_time: time2)
      post3.mark_read(user, at_time: time3)

      expect(post1.reload.last_read(user)).to be_nil

      post :mark, params: { marked_ids: [post1, post2, post3].map { |x| x.id.to_s } }

      aggregate_failures do
        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("3 posts hidden from this page.")
        expect(post1.reload.last_read(user)).to be_nil
        expect(post2.reload.last_read(user)).to be_the_same_time_as(time2)
        expect(post3.reload.last_read(user)).to be_the_same_time_as(time3)
      end
    end
  end

  context "not owed" do
    before(:each) { login_as(user) }

    it "requires full user" do
      user.update!(role_id: Permissible::READONLY)
      post :mark, params: { marked_ids: [reply_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    pending "requires post author" do
      post :mark, params: { marked_ids: [reply_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:error]).to eq("")
    end

    it "ignores invisible posts" do
      private_post.update!(authors: [user])
      post :mark, params: { marked_ids: [private_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("0 posts removed from replies owed.")
      expect(private_post.post_authors.find_by(user: user).can_owe).to eq(true)
    end

    it "deletes post author if the user has not yet joined" do
      post :mark, params: { marked_ids: [owed_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post removed from replies owed.")
      expect(owed_post.post_authors.find_by(user: user)).to be_nil
    end

    it "updates post author if the user has joined" do
      create(:reply, post: owed_post, user: user)

      post :mark, params: { marked_ids: [owed_post.id], commit: 'Remove from Replies Owed' }

      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post removed from replies owed.")
      expect(owed_post.post_authors.find_by(user: user).can_owe).to eq(false)
    end
  end

  context "newly owed" do
    before(:each) { login_as(user) }

    it "requires full user" do
      user.update!(role_id: Permissible::READONLY)
      post :mark, params: { marked_ids: [reply_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    pending "requires post author" do
      post :mark, params: { marked_ids: [reply_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:error]).to eq('')
    end

    it "ignores invisible posts" do
      private_post.update!(authors: [user])
      create(:reply, post: private_post, user: user)
      private_post.opt_out_of_owed(user)
      post :mark, params: { marked_ids: [private_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("0 posts added to replies owed.")
      expect(private_post.author_for(user).can_owe).to eq(false)
    end

    it "does nothing if the user has not yet joined" do
      owed_post.opt_out_of_owed(user)

      post :mark, params: { marked_ids: [owed_post.id], commit: 'Show in Replies Owed' }

      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post added to replies owed.")
      expect(owed_post.post_authors.find_by(user: user)).to be_nil
    end

    it "updates post author if the user has joined" do
      create(:reply, post: owed_post, user: user)
      owed_post.opt_out_of_owed(user)

      post :mark, params: { marked_ids: [owed_post.id], commit: 'Show in Replies Owed' }

      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post added to replies owed.")
      expect(owed_post.post_authors.find_by(user: user).can_owe).to eq(true)
    end
  end
end
