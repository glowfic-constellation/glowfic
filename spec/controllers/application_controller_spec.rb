require "spec_helper"

RSpec.describe ApplicationController do
  describe "#set_timezone" do
    it "uses the user's time zone within the block" do
      current_zone = Time.zone.name
      different_zone = ActiveSupport::TimeZone.all().detect { |z| z.name != Time.zone.name }.name
      session[:user_id] = create(:user, timezone: different_zone).id

      expect(Time.zone.name).to eq(current_zone)
      controller.send(:set_timezone) do
        expect(Time.zone.name).to eq(different_zone)
      end
    end

    it "succeeds when logged out" do
      current_zone = Time.zone.name
      expect(Time.zone.name).to eq(current_zone)
      controller.send(:set_timezone) do
        expect(Time.zone.name).to eq(current_zone)
      end
    end

    it "succeeds when logged in user has no zone set" do
      current_zone = Time.zone.name
      session[:user_id] = create(:user, timezone: nil).id
      expect(Time.zone.name).to eq(current_zone)
      controller.send(:set_timezone) do
        expect(Time.zone.name).to eq(current_zone)
      end
    end
  end

  describe "#show_password_warning" do
    it "shows no warning if logged out" do
      controller.send(:show_password_warning) do
        expect(flash.now[:pass]).not_to eq("Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site.")
      end
    end

    it "shows no warning for users with salt_uuid" do
      user = create(:user)
      login_as(user)
      expect(user.salt_uuid).not_to be_nil
      controller.send(:show_password_warning) do
        expect(flash.now[:pass]).not_to eq("Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site.")
        expect(controller.send(:logged_in?)).to be_true
      end
    end

    it "shows warning if salt_uuid not set" do
      user = create(:user)
      login_as(user)
      user.update_attribute(:salt_uuid, nil)
      controller.send(:show_password_warning) do
        expect(flash.now[:pass]).to eq("Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site.")
        expect(controller.send(:logged_in?)).not_to be_true
      end
    end
  end

  describe "#posts_from_relation" do
    it "gets posts" do
      post = create(:post)
      relation = Post.where('posts.id IS NOT NULL')
      expect(controller.send(:posts_from_relation, relation)).to match_array([post])
    end

    it "will return a blank array if applicable" do
      post = create(:post)
      relation = Post.where('posts.id IS NULL')
      expect(controller.send(:posts_from_relation, relation)).to be_blank
    end

    it "skips posts in site testing" do
      skip "stubbing constants does not seem to work well with scopes"

      post = create(:post, board: site_testing)
      stub_const("Board::ID_SITETESTING", site_testing.id)
      expect(Post.where(id: post.id).no_tests).to be_blank # fails
      relation = Post.where(id: post.id)
      expect(controller.send(:posts_from_relation, relation), true).to be_blank # so this fails
    end

    it "can be made to show site testing posts" do
      skip "stubbing constants does not seem to work well with scopes"

      site_testing = create(:board)
      stub_const("Board::ID_SITETESTING", site_testing.id)
      post = create(:post, board: site_testing)
      relation = Post.where(id: post.id)
      expect(controller.send(:posts_from_relation, relation), false).not_to be_blank
    end

    let(:default_post_ids) { 26.times.collect do create(:post) end.map(&:id) }

    it "paginates by default" do
      relation = Post.where(id: default_post_ids)
      fetched_posts = controller.send(:posts_from_relation, relation)
      expect(fetched_posts.total_pages).to eq(2)
    end

    it "allows pagination to be disabled" do
      relation = Post.where(id: default_post_ids)
      fetched_posts = controller.send(:posts_from_relation, relation, true, false)
      expect(fetched_posts).not_to respond_to(:total_pages)
    end

    it "skips visibility check if there are more than 25 posts" do
      expect_any_instance_of(Post).not_to receive(:visible_to?)
      relation = Post.where(id: default_post_ids)
      fetched_posts = controller.send(:posts_from_relation, relation)
      expect(fetched_posts.count).to eq(26) # number when querying the database – actual number returned is 25, due to pagination
    end

    context "when logged in" do
      it "returns empty array if no visible posts" do
        hidden_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
        user = create(:user)
        login_as(user)
        expect(hidden_post).not_to be_visible_to(user)

        relation = Post.where(id: hidden_post.id)
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to be_empty
      end

      it "filters array if mixed visible and not visible posts" do
        hidden_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
        public_post = create(:post, privacy: Post::PRIVACY_PUBLIC)
        user = create(:user)
        own_post = create(:post, user: user, privacy: Post::PRIVACY_PUBLIC)
        login_as(user)

        relation = Post.where(id: [hidden_post.id, public_post.id, own_post.id])
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to match_array([public_post, own_post])
      end

      it "sets opened_ids and unread_ids properly" do
        user = create(:user)
        login_as(user)
        time = Time.now - 5.minutes
        unopened1, unopened2, partread, read1, read2, hidden_unread, hidden_partread = posts = Timecop.freeze(time) do
          unopened1 = create(:post) # post
          unopened2 = create(:post) # post, reply
          partread = create(:post) # post, reply
          read1 = create(:post) # post
          read2 = create(:post) # post, reply
          hidden_unread = create(:post) # post
          hidden_partread = create(:post) # post, reply

          partread.mark_read(user)
          read1.mark_read(user)
          hidden_partread.mark_read(user)

          [unopened1, unopened2, partread, read1, read2, hidden_unread, hidden_partread]
        end

        unopened2_reply, partread_reply, read2_reply, hidden_partread_reply = Timecop.freeze(time + 1.minute) do
          unopened2_reply = create(:reply, post: unopened2)
          partread_reply = create(:reply, post: partread)
          read2_reply = create(:reply, post: read2)
          hidden_partread_reply = create(:reply, post: hidden_partread)

          read2.mark_read(user)

          [unopened2_reply, partread_reply, read2_reply, hidden_partread_reply]
        end

        hidden_unread.ignore(user)
        hidden_partread.ignore(user)

        relation = Post.where(id: posts.map(&:id))
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to match_array(posts)
        expect(assigns(:opened_ids)).to match_array([partread, read1, read2, hidden_partread].map(&:id))
        expect(assigns(:unread_ids)).to match_array([partread, hidden_partread].map(&:id))
      end
    end

    context "when logged out" do
      it "returns empty array if no visible posts" do
        hidden_post = create(:post, privacy: Post::PRIVACY_PRIVATE)

        relation = Post.where(id: hidden_post.id)
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to be_empty
      end

      it "filters array if mixed visible and not visible posts" do
        hidden_post = create(:post, privacy: Post::PRIVACY_PRIVATE)
        public_post = create(:post, privacy: Post::PRIVACY_PUBLIC)
        conste_post = create(:post, privacy: Post::PRIVACY_REGISTERED)

        relation = Post.where(id: [hidden_post.id, public_post.id, conste_post.id])
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to match_array([public_post])
      end
    end

    it "has more tests" do
      skip
    end
  end
end
