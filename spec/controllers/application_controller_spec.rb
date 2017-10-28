require "spec_helper"

RSpec.describe ApplicationController do
  describe "#set_timezone" do
    it "uses the user's time zone within the block" do
      current_zone = Time.zone.name
      different_zone = ActiveSupport::TimeZone.all.detect { |z| z.name != Time.zone.name }.name
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
        expect(controller.send(:logged_in?)).to eq(true)
      end
    end

    it "shows warning if salt_uuid not set" do
      user = create(:user)
      login_as(user)
      user.update_attribute(:salt_uuid, nil)
      controller.send(:show_password_warning) do
        expect(flash.now[:pass]).to eq("Because Marri accidentally made passwords a bit too secure, you must log back in to continue using the site.")
        expect(controller.send(:logged_in?)).not_to eq(true)
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
      create(:post)
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

    let(:default_post_ids) { Array.new(26) do create(:post).id end }

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

    it "fetches correct authors, reply counts and content warnings" do
      post1 = create(:post)
      warning1 = create(:content_warning)
      post2 = create(:post, content_warnings: [warning1])
      post2_reply = create(:reply, post: post2)
      warning2 = create(:content_warning)
      post3 = create(:post, content_warnings: [warning1, warning2])
      post3_user2 = create(:user)
      post3_user3 = create(:user)
      25.times { |i| create(:reply, post: post3, user: post3_user2) }
      10.times { |i| create(:reply, post: post3, user: post3_user3)}

      id_list = [post1.id, post2.id, post3.id]
      relation = Post.where(id: id_list).order('id asc')
      fetched_posts = controller.send(:posts_from_relation, relation)
      expect(fetched_posts.count).to eq(3)
      expect(fetched_posts.map(&:id)).to match_array(id_list)

      fetched1 = fetched_posts[0]
      fetched2 = fetched_posts[1]
      fetched3 = fetched_posts[2]

      expect(fetched1.has_content_warnings?).not_to eq(true)
      expect(fetched2.has_content_warnings?).to eq(true)
      expect(fetched3.has_content_warnings?).to eq(true)
      expect(fetched2.content_warnings).to match_array([warning1])
      expect(fetched3.content_warnings).to match_array([warning1, warning2])

      expect(fetched1.reply_count).to eq(0)
      expect(fetched2.reply_count).to eq(1)
      expect(fetched3.reply_count).to eq(35)

      expect(fetched1.authors).to match_array([post1.user])
      expect(fetched2.authors).to match_array([post2.user, post2_reply.user])
      expect(fetched3.authors).to match_array([post3.user, post3_user2, post3_user3])
      expect(fetched1.author_ids).to match_array([post1.user_id])
      expect(fetched2.author_ids).to match_array([post2.user_id, post2_reply.user_id])
      expect(fetched3.author_ids).to match_array([post3.user_id, post3_user2.id, post3_user3.id])
    end

    context "when logged in" do
      it "returns empty array if no visible posts" do
        hidden_post = create(:post, privacy: Concealable::PRIVATE)
        user = create(:user)
        login_as(user)
        expect(hidden_post).not_to be_visible_to(user)

        relation = Post.where(id: hidden_post.id)
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to be_empty
      end

      it "filters array if mixed visible and not visible posts" do
        hidden_post = create(:post, privacy: Concealable::PRIVATE)
        public_post = create(:post, privacy: Concealable::PUBLIC)
        user = create(:user)
        own_post = create(:post, user: user, privacy: Concealable::PUBLIC)
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
        hidden_post = create(:post, privacy: Concealable::PRIVATE)

        relation = Post.where(id: hidden_post.id)
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to be_empty
      end

      it "filters array if mixed visible and not visible posts" do
        hidden_post = create(:post, privacy: Concealable::PRIVATE)
        public_post = create(:post, privacy: Concealable::PUBLIC)
        conste_post = create(:post, privacy: Concealable::REGISTERED)

        relation = Post.where(id: [hidden_post.id, public_post.id, conste_post.id])
        fetched_posts = controller.send(:posts_from_relation, relation)
        expect(fetched_posts).to match_array([public_post])
      end
    end

    it "has more tests" do
      skip
    end
  end

  describe "#page_view" do
    context "when logged out" do
      it "works by default" do
        expect(controller.send(:page_view)).to eq('icon')
      end

      it "can be overridden with a parameter" do
        controller.params[:view] = 'list'
        expect(session[:view]).to be_nil
        expect(controller.send(:page_view)).to eq('list')
        expect(session[:view]).to eq('list')
      end

      it "uses session variable if it exists" do
        session[:view] = 'list'
        expect(controller.send(:page_view)).to eq('list')
      end
    end

    context "when logged in" do
      it "works by default" do
        login
        expect(controller.send(:page_view)).to eq('icon')
      end

      it "uses account default if different" do
        user = create(:user, default_view: 'list')
        login_as(user)
        expect(controller.send(:page_view)).to eq('list')
      end

      it "is not overridden by session" do
        # also does not modify user default
        user = create(:user, default_view: 'list')
        login_as(user)
        session[:view] = 'icon'
        expect(controller.send(:page_view)).to eq('list')
        expect(user.reload.default_view).to eq('list')
      end

      it "can be overridden by params" do
        # also does not modify user default
        user = create(:user, default_view: 'list')
        login_as(user)
        controller.params[:view] = 'icon'
        expect(controller.send(:page_view)).to eq('icon')
        expect(user.reload.default_view).to eq('list')
      end
    end
  end
end
