RSpec.shared_examples "logged out post list" do
  it "does not show user-only posts", :aggregate_failures do
    posts = create_list(:post, 2)
    create_list(:post, 2, privacy: :registered)
    create_list(:post, 2, privacy: :full_accounts)
    get controller_action, params: params
    expect(response.status).to eq(200)
    expect(Post.count).to eq(6)
    expect(assigns(assign_variable)).to match_array(posts)
  end
end

RSpec.shared_examples "logged in post list" do
  let(:user) { create(:user) }
  let!(:posts) { create_list(:post, 3) }

  before(:each) { login_as(user) }

  context "with private posts", :aggregate_failures do
    let!(:private_post) { create(:post, privacy: :private) }
    let!(:access_post) { create(:post, privacy: :access_list) }

    it "does not show access-locked or private threads" do
      get controller_action, params: params
      expect(response.status).to eq(200)
      expect(assigns(assign_variable)).to match_array(posts)
    end

    it "shows access-locked and private threads if you have access" do
      private_post.update!(user: user)
      access_post.update!(viewers: [user])

      get controller_action, params: params
      expect(response.status).to eq(200)
      expect(assigns(assign_variable)).to match_array(posts + [private_post, access_post])
    end
  end

  context "with limited access posts", :aggregate_failures do
    let!(:limited_post) { create(:post, privacy: :full_accounts) }

    it "does not show limited access threads to reader accounts" do
      user.update!(role_id: Permissible::READONLY)
      get controller_action, params: params
      expect(response.status).to eq(200)
      expect(assigns(assign_variable)).to match_array(posts)
    end

    it "shows limited access threads to full accounts" do
      get controller_action, params: params
      expect(response.status).to eq(200)
      expect(assigns(assign_variable)).to match_array(posts + [limited_post])
    end
  end

  context "with blocking", :aggregate_failures do
    let!(:blocked_user) { create(:user) }
    let!(:blocking_user) { create(:user) }

    context "with locked posts" do
      let!(:blocking_post) { create(:post, user: blocking_user, authors_locked: true) }
      let!(:blocked_post) { create(:post, user: blocked_user, authors_locked: true) }

      context "with post blocks" do
        before(:each) do
          create(:block, blocking_user: user, blocked_user: blocked_user, hide_them: :posts)
          create(:block, blocking_user: blocking_user, blocked_user: user, hide_me: :posts)
        end

        it "does not show posts with blocked or blocking authors" do
          get controller_action, params: params
          expect(response.status).to eq(200)
          expect(assigns(assign_variable)).to match_array(posts)
        end

        it "shows posts with a blocked (but not blocking) author with show_blocked" do
          params[:show_blocked] = true
          get controller_action, params: params
          expect(response.status).to eq(200)
          expect(assigns(assign_variable)).to match_array(posts + [blocked_post])
        end

        it "shows your own posts with blocking but not blocked authors" do
          blocked_post.update!(unjoined_authors: [user])
          create(:reply, post: blocked_post, user: user)
          blocking_post.update!(unjoined_authors: [user])
          create(:reply, post: blocking_post, user: user)

          get controller_action, params: params
          expect(response.status).to eq(200)
          expect(assigns(assign_variable)).to match_array(posts + [blocking_post])
        end
      end

      it "does not show posts with full blocked or blocking authors" do
        create(:block, blocking_user: user, blocked_user: blocked_user, hide_them: :all)
        create(:block, blocking_user: blocking_user, blocked_user: user, hide_me: :all)
        get controller_action, params: params
        expect(response.status).to eq(200)
        expect(assigns(assign_variable)).to match_array(posts)
      end
    end

    context "with unlocked posts", :aggregate_failures do
      let!(:blocking_post) { create(:post, user: blocking_user, authors_locked: false) }
      let!(:blocked_post) { create(:post, user: blocked_user, authors_locked: false) }

      it "shows unlocked posts with incomplete blocking" do
        create(:block, blocking_user: user, blocked_user: blocked_user, hide_them: :posts)
        create(:block, blocking_user: blocking_user, blocked_user: user, hide_me: :posts)
        get controller_action, params: params
        expect(response.status).to eq(200)
        expect(assigns(assign_variable)).to match_array(posts + [blocking_post, blocked_post])
      end

      context "with full viewer-side blocking" do
        before(:each) do
          create(:block, blocking_user: user, blocked_user: blocked_user, hide_them: :all)
          blocking_post.destroy!
        end

        it "does not show unlocked posts" do
          get controller_action, params: params
          expect(response.status).to eq(200)
          expect(assigns(assign_variable)).to match_array(posts)
        end

        it "shows unlocked posts as author" do
          create(:reply, post: blocked_post, user: user)
          get controller_action, params: params
          expect(response.status).to eq(200)
          expect(assigns(assign_variable)).to match_array(posts + [blocked_post])
        end
      end

      it "shows unlocked posts with full author-side blocking" do
        blocked_post.destroy!
        create(:block, blocking_user: blocking_user, blocked_user: user, hide_me: :all)
        get controller_action, params: params
        expect(response.status).to eq(200)
        expect(assigns(assign_variable)).to match_array(posts + [blocking_post])
      end
    end
  end
end
