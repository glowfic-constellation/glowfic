RSpec.describe PostsController do
  let(:user) { create(:user) }
  let(:coauthor) { create(:user) }
  let(:user_post) { create(:post, user: user) }

  describe "GET #merge" do
    it "requires login" do
      get :merge, params: { id: user_post.id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires edit permissions" do
      login
      get :merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires locked authorship" do
      login_as(user)
      user_post.update!(authors_locked: false)
      get :merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Post must be locked to current authors.")
    end

    it "works for creator if locked" do
      login_as(user)
      user_post.update!(authors_locked: true)
      get :merge, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end

    it "works for coauthor if locked" do
      login_as(coauthor)
      create(:reply, post: user_post, user: coauthor)
      user_post.update!(authors_locked: true)
      get :merge, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end

    it "works for mod if locked" do
      login_as(create(:mod_user))
      user_post.update!(authors_locked: true)
      get :merge, params: { id: user_post.id }
      expect(response).to have_http_status(200)
    end

    context "with render_views" do
      render_views

      it "renders" do
        login_as(user)
        user_post.update!(authors_locked: true)
        get :merge, params: { id: user_post.id }
        expect(response).to have_http_status(200)
        expect(response.body).to include("Merge Post")
      end
    end
  end

  describe "POST #preview_merge" do
    it "requires login" do
      post :preview_merge, params: { id: user_post.id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires edit permissions" do
      login
      post :preview_merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires locked authorship" do
      login_as(user)
      user_post.update!(authors_locked: false)
      post :preview_merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Post must be locked to current authors.")
    end

    context "with a mergeable post" do
      let(:target_post) { create(:post, user: user, authors_locked: true) }
      let(:target_reply) { create(:reply, post: target_post, user: user) }

      before(:each) do
        login_as(user)
        user_post.update!(authors_locked: true)
      end

      it "rejects a blank link" do
        post :preview_merge, params: { id: user_post.id, target_url: '' }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("Could not recognize that link as a post or reply.")
      end

      it "rejects an unparseable link" do
        post :preview_merge, params: { id: user_post.id, target_url: 'not a link' }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("Could not recognize that link as a post or reply.")
      end

      it "rejects a link that is not a post or reply" do
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/users/#{user.id}" }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("Could not recognize that link as a post or reply.")
      end

      it "rejects a link to a nonexistent post" do
        post :preview_merge, params: { id: user_post.id, target_url: 'https://glowfic.com/posts/-1' }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("Could not recognize that link as a post or reply.")
      end

      it "rejects a link to the post itself" do
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{user_post.id}" }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("A post cannot be merged into itself.")
      end

      it "rejects a link to a reply of the post itself" do
        reply = create(:reply, post: user_post, user: user)
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/replies/#{reply.id}" }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("A post cannot be merged into itself.")
      end

      it "rejects a target the user is not an author of" do
        other_post = create(:post, authors_locked: true)
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{other_post.id}" }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("You must be an author of the other post, and it must be locked to its current authors.")
      end

      it "rejects an unlocked target" do
        target_post.update!(authors_locked: false)
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }
        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("You must be an author of the other post, and it must be locked to its current authors.")
      end

      it "rejects a target an author of this post cannot see" do
        create(:post_author, post: user_post, user: coauthor)
        target_post.update!(privacy: :access_list)
        target_post.viewers << user

        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("Visibility or blocking settings prevent some authors of at least one of the posts from seeing the other.")
      end

      it "rejects a post the target's authors cannot see" do
        create(:post_author, post: target_post, user: create(:user))
        user_post.update!(privacy: :access_list)
        user_post.viewers << user

        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("Visibility or blocking settings prevent some authors of at least one of the posts from seeing the other.")
      end

      it "rejects a merge where an author blocks another from their posts" do
        target_coauthor = create(:user)
        create(:post_author, post: target_post, user: target_coauthor)
        create(:post_author, post: user_post, user: coauthor)
        create(:block, blocking_user: coauthor, blocked_user: target_coauthor, hide_me: :posts)

        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(response).to render_template(:merge)
        expect(flash[:error]).to eq("Visibility or blocking settings prevent some authors of at least one of the posts from seeing the other.")
      end

      it "accepts a post link, targeting its top post" do
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }
        expect(response).to render_template(:preview_merge)
        expect(assigns(:target_reply)).to eq(target_post.written)
      end

      it "accepts a reply link" do
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/replies/#{target_reply.id}" }
        expect(response).to render_template(:preview_merge)
        expect(assigns(:target_reply)).to eq(target_reply)
      end

      it "accepts a relative link" do
        post :preview_merge, params: { id: user_post.id, target_url: "/replies/#{target_reply.id}" }
        expect(response).to render_template(:preview_merge)
        expect(assigns(:target_reply)).to eq(target_reply)
      end

      it "accepts someone else's target for mods" do
        other_post = create(:post, authors_locked: true)
        login_as(create(:mod_user))
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{other_post.id}" }
        expect(response).to render_template(:preview_merge)
        expect(assigns(:target_reply)).to eq(other_post.written)
      end

      it "merges tags without duplicates" do
        shared = create(:setting)
        user_post.update!(settings: [shared, create(:setting)], content_warnings: [create(:content_warning)])
        target_post.update!(settings: [shared], labels: [create(:label)])

        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(assigns(:settings)).to match_array((user_post.settings + target_post.settings).uniq)
        expect(assigns(:settings).size).to eq(2)
        expect(assigns(:content_warnings)).to match_array(user_post.content_warnings)
        expect(assigns(:labels)).to match_array(target_post.labels)
      end

      it "defaults to the stricter privacy" do
        user_post.update!(privacy: :full_accounts)
        target_post.update!(privacy: :registered)

        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(assigns(:default_privacy)).to eq(:full_accounts)
      end

      it "treats an access list as stricter than full accounts" do
        # the privacy enum's integer order does not reflect strictness
        user_post.update!(privacy: :access_list)
        user_post.viewers << coauthor
        target_post.update!(privacy: :full_accounts)

        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(assigns(:default_privacy)).to eq(:access_list)
      end

      it "warns about mismatching privacies" do
        user_post.update!(privacy: :registered)

        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(response).to render_template(:preview_merge)
        expected_error = "Source and target posts have mismatching privacy levels; the stricter privacy level has been selected by default."
        expect(flash[:error]).to eq(expected_error)
      end

      it "does not warn about matching privacies" do
        post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }

        expect(response).to render_template(:preview_merge)
        expect(flash[:error]).to be_nil
      end

      context "with render_views" do
        render_views

        it "renders the target post header for a top post target" do
          target_post.update!(description: 'the target description')
          post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/posts/#{target_post.id}" }
          expect(response.body).to include(target_post.subject)
          expect(response.body).to include('the target description')
          expect(response.body).to include('Finish Merge')
        end

        it "does not render the target post header for a reply target" do
          target_post.update!(description: 'the target description')
          post :preview_merge, params: { id: user_post.id, target_url: "https://glowfic.com/replies/#{target_reply.id}" }
          expect(response.body).not_to include('the target description')
          expect(response.body).to include('Finish Merge')
        end
      end
    end
  end

  describe "POST #do_merge" do
    it "requires login" do
      post :do_merge, params: { id: user_post.id }
      expect(response).to redirect_to(root_url)
      expect(flash[:error]).to eq("You must be logged in to view that page.")
    end

    it "requires edit permissions" do
      login
      post :do_merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end

    it "requires locked authorship" do
      login_as(user)
      user_post.update!(authors_locked: false)
      post :do_merge, params: { id: user_post.id }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Post must be locked to current authors.")
    end

    context "with a mergeable post" do
      let(:target_post) { create(:post, user: user, authors_locked: true) }
      let(:target_reply) { create(:reply, post: target_post, user: user) }

      before(:each) do
        login_as(user)
        user_post.update!(authors_locked: true)
      end

      it "rejects a missing target reply" do
        post :do_merge, params: { id: user_post.id, target_reply_id: -1, post: { privacy: 'public' } }
        expect(response).to redirect_to(merge_post_url(user_post))
        expect(flash[:error]).to eq("Could not recognize that link as a post or reply.")
      end

      it "rejects a reply of the post itself" do
        reply = create(:reply, post: user_post, user: user)
        post :do_merge, params: { id: user_post.id, target_reply_id: reply.id, post: { privacy: 'public' } }
        expect(response).to redirect_to(merge_post_url(user_post))
        expect(flash[:error]).to eq("A post cannot be merged into itself.")
      end

      it "rejects an unlocked target" do
        target_post.update!(authors_locked: false)
        post :do_merge, params: { id: user_post.id, target_reply_id: target_reply.id, post: { privacy: 'public' } }
        expect(response).to redirect_to(merge_post_url(user_post))
        expect(flash[:error]).to eq("You must be an author of the other post, and it must be locked to its current authors.")
      end

      it "rejects an unrecognized privacy" do
        post :do_merge, params: { id: user_post.id, target_reply_id: target_reply.id, post: { privacy: 'secret' } }
        expect(response).to redirect_to(merge_post_url(user_post))
        expect(flash[:error]).to eq("Privacy could not be recognized.")
      end

      it "accepts an access list privacy for co-authored posts" do
        # the merge adds all authors to the access list, so co-authors are exempt from the recheck
        create(:post_author, post: user_post, user: coauthor)
        expect {
          post :do_merge, params: { id: user_post.id, target_reply_id: target_reply.id, post: { privacy: 'access_list' } }
        }.to enqueue_job(MergePostsJob).exactly(:once)
        expect(response).to redirect_to(post_url(target_post))
        expect(flash[:success]).to eq("The posts will be merged.")
      end

      it "rejects a privacy that would hide the merged post from an author" do
        create(:post_author, post: user_post, user: coauthor)
        post :do_merge, params: { id: user_post.id, target_reply_id: target_reply.id, post: { privacy: 'private' } }
        expect(response).to redirect_to(merge_post_url(user_post))
        expect(flash[:error]).to eq("Visibility or blocking settings prevent some authors of at least one of the posts from seeing the other.")
        expect(target_post.reload.privacy).to eq('public')
      end

      it "enqueues the merge" do
        setting = create(:setting)
        label = create(:label)
        expect {
          post :do_merge, params: {
            id: user_post.id,
            target_reply_id: target_reply.id,
            post: { privacy: 'registered', setting_ids: [setting.id.to_s], label_ids: [label.id.to_s] },
          }
        }.to enqueue_job(MergePostsJob).exactly(:once).with(user_post.id, target_reply.id, 'registered', [setting.id], [], [label.id])
        expect(response).to redirect_to(post_url(target_post))
        expect(flash[:success]).to eq("The posts will be merged.")
        expect(target_post.reload.privacy).to eq('public') # applied by the job, not the controller
      end

      it "merges private posts with a single author" do
        user_post.update!(privacy: :private)
        target_post.update!(privacy: :private)
        expect {
          post :do_merge, params: { id: user_post.id, target_reply_id: target_reply.id, post: { privacy: 'private' } }
        }.to enqueue_job(MergePostsJob).exactly(:once)
        expect(response).to redirect_to(post_url(target_post))
        expect(flash[:success]).to eq("The posts will be merged.")
      end

      it "rejects invalid new tags without crashing" do
        expect {
          post :do_merge, params: {
            id: user_post.id,
            target_reply_id: target_reply.id,
            post: { privacy: 'public', content_warning_ids: ['_'] },
          }
        }.not_to change { ContentWarning.count }
        expect(response).to redirect_to(merge_post_url(user_post))
        expect(flash[:error]).to start_with("Tags could not be created:")
      end

      it "creates new tags typed into the form" do
        expect {
          post :do_merge, params: {
            id: user_post.id,
            target_reply_id: target_reply.id,
            post: { privacy: 'public', content_warning_ids: ['_brand new warning'] },
          }
        }.to change { ContentWarning.count }.by(1)
        expect(ContentWarning.last.name).to eq('brand new warning')
      end
    end
  end
end
