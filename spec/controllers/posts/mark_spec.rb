RSpec.describe PostsController, 'POST mark' do
  it "requires login" do
    post :mark
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  context "read" do
    it "skips invisible post" do
      private_post = create(:post, privacy: :private)
      user = create(:user)
      expect(private_post.visible_to?(user)).not_to eq(true)
      login_as(user)
      post :mark, params: { marked_ids: [private_post.id], commit: "Mark Read" }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("0 posts marked as read.")
      expect(private_post.reload.last_read(user)).to be_nil
    end

    it "reads posts" do
      user = create(:user)
      post1 = create(:post)
      post2 = create(:post)
      login_as(user)

      expect(post1.last_read(user)).to be_nil
      expect(post2.last_read(user)).to be_nil

      post :mark, params: { marked_ids: [post1.id.to_s, post2.id.to_s], commit: "Mark Read" }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts marked as read.")
      expect(post1.reload.last_read(user)).not_to be_nil
      expect(post2.reload.last_read(user)).not_to be_nil
    end

    it "works for reader users" do
      user = create(:reader_user)
      posts = create_list(:post, 2)
      login_as(user)

      post :mark, params: { marked_ids: posts.map(&:id).map(&:to_s), commit: "Mark Read" }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts marked as read.")
    end
  end

  context "ignored" do
    it "skips invisible post" do
      private_post = create(:post, privacy: :private)
      user = create(:user)
      expect(private_post.visible_to?(user)).not_to eq(true)
      login_as(user)
      post :mark, params: { marked_ids: [private_post.id] }
      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("0 posts hidden from this page.")
      expect(private_post.reload.ignored_by?(user)).not_to eq(true)
    end

    it "ignores posts" do
      user = create(:user)
      post1 = create(:post)
      post2 = create(:post)
      login_as(user)

      expect(post1.visible_to?(user)).to eq(true)
      expect(post2.visible_to?(user)).to eq(true)

      post :mark, params: { marked_ids: [post1.id.to_s, post2.id.to_s] }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts hidden from this page.")
      expect(post1.reload.ignored_by?(user)).to eq(true)
      expect(post2.reload.ignored_by?(user)).to eq(true)
    end

    it "works for reader users" do
      user = create(:reader_user)
      posts = create_list(:post, 2)
      login_as(user)

      post :mark, params: { marked_ids: posts.map(&:id).map(&:to_s) }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("2 posts hidden from this page.")
    end

    it "does not mess with read timestamps" do
      user = create(:user)

      time = Time.zone.now - 10.minutes
      post1 = create(:post, created_at: time, updated_at: time) # unread
      post2 = create(:post, created_at: time, updated_at: time) # partially read
      post3 = create(:post, created_at: time, updated_at: time) # fully read
      Array.new(5) { |i| create(:reply, post: post1, created_at: time + i.minutes, updated_at: time + i.minutes) } # replies1
      replies2 = Array.new(5) { |i| create(:reply, post: post2, created_at: time + i.minutes, updated_at: time + i.minutes) }
      replies3 = Array.new(5) { |i| create(:reply, post: post3, created_at: time + i.minutes, updated_at: time + i.minutes) }

      login_as(user)
      expect(post1).to be_visible_to(user)
      expect(post2).to be_visible_to(user)
      expect(post3).to be_visible_to(user)

      time2 = replies2.first.updated_at
      time3 = replies3.last.updated_at
      post2.mark_read(user, at_time: time2)
      post3.mark_read(user, at_time: time3)

      expect(post1.reload.last_read(user)).to be_nil
      expect(post2.reload.last_read(user)).to be_the_same_time_as(time2)
      expect(post3.reload.last_read(user)).to be_the_same_time_as(time3)

      post :mark, params: { marked_ids: [post1, post2, post3].map(&:id).map(&:to_s) }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("3 posts hidden from this page.")
      expect(post1.reload.last_read(user)).to be_nil
      expect(post2.reload.last_read(user)).to be_the_same_time_as(time2)
      expect(post3.reload.last_read(user)).to be_the_same_time_as(time3)
    end
  end

  context "not owed" do
    it "requires full user" do
      user = create(:reader_user)
      reply_post = create(:post)
      login_as(user)
      post :mark, params: { marked_ids: [reply_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    pending "requires post author" do
      user = create(:user)
      unowed_post = create(:post)
      login_as(user)
      post :mark, params: { marked_ids: [unowed_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:error]).to eq("")
    end

    it "ignores invisible posts" do
      user = create(:user)
      private_post = create(:post, privacy: :private, authors: [user])
      expect(private_post.visible_to?(user)).not_to eq(true)
      expect(private_post.post_authors.find_by(user: user).can_owe).to eq(true)
      login_as(user)
      post :mark, params: { marked_ids: [private_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("0 posts removed from replies owed.")
      expect(private_post.post_authors.find_by(user: user).can_owe).to eq(true)
    end

    it "deletes post author if the user has not yet joined" do
      user = create(:user)
      owed_post = create(:post, unjoined_authors: [user])
      expect(owed_post.post_authors.find_by(user: user).can_owe).to eq(true)
      login_as(user)
      post :mark, params: { marked_ids: [owed_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post removed from replies owed.")
      expect(owed_post.post_authors.find_by(user: user)).to be_nil
    end

    it "updates post author if the user has joined" do
      user = create(:user)
      owed_post = create(:post, unjoined_authors: [user])
      create(:reply, post: owed_post, user: user)
      expect(owed_post.post_authors.find_by(user: user).can_owe).to eq(true)
      expect(owed_post.post_authors.find_by(user: user).joined).to eq(true)
      login_as(user)
      post :mark, params: { marked_ids: [owed_post.id], commit: 'Remove from Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post removed from replies owed.")
      expect(owed_post.post_authors.find_by(user: user).can_owe).to eq(false)
    end
  end

  context "newly owed" do
    it "requires full user" do
      user = create(:reader_user)
      reply_post = create(:post)
      login_as(user)
      post :mark, params: { marked_ids: [reply_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(continuities_path)
      expect(flash[:error]).to eq("This feature is not available to read-only accounts.")
    end

    pending "requires post author" do
      user = create(:user)
      unowed_post = create(:post)
      login_as(user)
      post :mark, params: { marked_ids: [unowed_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:error]).to eq('')
    end

    it "ignores invisible posts" do
      user = create(:user)
      private_post = create(:post, privacy: :private, authors: [user])
      expect(private_post.visible_to?(user)).not_to eq(true)
      private_post.author_for(user).update!(can_owe: false)
      login_as(user)
      post :mark, params: { marked_ids: [private_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("0 posts added to replies owed.")
      expect(private_post.post_authors.find_by(user: user).can_owe).to eq(false)
    end

    it "does nothing if the user has not yet joined" do
      user = create(:user)
      owed_post = create(:post, unjoined_authors: [user])
      owed_post.opt_out_of_owed(user)
      expect(owed_post.author_for(user)).to be_nil
      login_as(user)
      post :mark, params: { marked_ids: [owed_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post added to replies owed.")
      expect(owed_post.post_authors.find_by(user: user)).to be_nil
    end

    it "updates post author if the user has joined" do
      user = create(:user)
      owed_post = create(:post, unjoined_authors: [user])
      create(:reply, post: owed_post, user: user)
      expect(owed_post.post_authors.find_by(user: user).joined).to eq(true)
      owed_post.opt_out_of_owed(user)
      expect(owed_post.post_authors.find_by(user: user).can_owe).to eq(false)
      login_as(user)
      post :mark, params: { marked_ids: [owed_post.id], commit: 'Show in Replies Owed' }
      expect(response).to redirect_to(owed_posts_url)
      expect(flash[:success]).to eq("1 post added to replies owed.")
      expect(owed_post.post_authors.find_by(user: user).can_owe).to eq(true)
    end
  end
end
