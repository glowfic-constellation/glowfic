RSpec.describe PostsController, 'PUT update' do
  it "requires login" do
    put :update, params: { id: -1 }
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    skip "TODO Currently relies on inability to create posts"
  end

  it "requires valid post" do
    login
    put :update, params: { id: -1 }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("Post could not be found.")
  end

  it "requires post be visible to user" do
    post = create(:post, privacy: :private)
    user = create(:user)
    login_as(user)
    expect(post.visible_to?(user)).not_to eq(true)

    put :update, params: { id: post.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "requires notes from moderators" do
    post = create(:post, privacy: :private)
    login_as(create(:admin_user))
    put :update, params: { id: post.id }
    expect(response).to render_template(:edit)
    expect(flash[:error]).to eq('You must provide a reason for your moderator edit.')
  end

  it "does not require note from coauthors" do
    post = create(:post, privacy: :access_list)
    user = create(:user)
    post.viewers << user
    post.authors << user
    login_as(user)
    put :update, params: { id: post.id }
    expect(flash[:success]).not_to be_nil
    expect(flash[:error]).not_to eq('You must provide a reason for your moderator edit.')
  end

  it "stores note from moderators" do
    Post.auditing_enabled = true
    post = create(:post, privacy: :private)
    admin = create(:admin_user)
    login_as(admin)
    put :update, params: {
      id: post.id,
      post: { description: 'b', audit_comment: 'note' },
    }
    expect(flash[:success]).to eq("Your post has been updated.")
    expect(post.reload.description).to eq('b')
    expect(post.audits.last.comment).to eq('note')
    Post.auditing_enabled = false
  end

  context "mark unread" do
    # rubocop:disable RSpec/RepeatedExample
    it "requires valid at_id" do
      skip "TODO does not notify"
    end

    it "requires post's at_id" do
      skip "TODO does not notify"
    end
    # rubocop:enable RSpec/RepeatedExample

    it "works with at_id" do
      post = create(:post)
      unread_reply = build(:reply, post: post)
      Timecop.freeze(post.created_at + 1.minute) do
        unread_reply.save!
        create(:reply, post: post)
      end
      Timecop.freeze(post.created_at + 2.minutes) do
        post.mark_read(post.user)
      end
      expect(post.last_read(post.user)).to be_the_same_time_as(post.created_at + 2.minutes)
      login_as(post.user)

      put :update, params: { id: post.id, unread: true, at_id: unread_reply.id }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("Post has been marked as read until reply ##{unread_reply.id}.")
      expect(post.reload.last_read(post.user)).to be_the_same_time_as((unread_reply.created_at - 1.second))
      expect(post.reload.first_unread_for(post.user)).to eq(unread_reply)
    end

    it "works without at_id" do
      post = create(:post)
      user = create(:user)
      post.mark_read(user)
      expect(post.reload.send(:view_for, user)).not_to be_nil
      login_as(user)

      put :update, params: { id: post.id, unread: true }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("Post has been marked as unread")
      expect(post.reload.first_unread_for(user)).to eq(post)
    end

    it "works when ignored with at_id" do
      user = create(:user)
      post = create(:post)
      unread_reply = build(:reply, post: post)
      Timecop.freeze(post.created_at + 1.minute) do
        unread_reply.save!
        create(:reply, post: post)
      end
      Timecop.freeze(post.created_at + 2.minutes) do
        post.mark_read(user)
        post.ignore(user)
      end
      expect(post.reload.first_unread_for(user)).to be_nil
      login_as(user)

      put :update, params: { id: post.id, unread: true, at_id: unread_reply.id }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("Post has been marked as read until reply ##{unread_reply.id}.")
      expect(post.reload.last_read(user)).to be_the_same_time_as((unread_reply.created_at - 1.second))
      expect(post.reload.first_unread_for(user)).to eq(unread_reply)
      expect(post).to be_ignored_by(user)
    end

    it "works when ignored without at_id" do
      post = create(:post)
      user = create(:user)
      post.mark_read(user)
      post.ignore(user)
      expect(post.reload.first_unread_for(user)).to be_nil
      login_as(user)

      put :update, params: { id: post.id, unread: true }

      expect(response).to redirect_to(unread_posts_url)
      expect(flash[:success]).to eq("Post has been marked as unread")
      expect(post.reload.first_unread_for(user)).to eq(post)
    end
  end

  context "change status" do
    it "requires permission" do
      post = create(:post)
      login
      put :update, params: { id: post.id, status: 'complete' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
      expect(post.reload).to be_active
    end

    it "requires valid status" do
      post = create(:post)
      login_as(post.user)
      put :update, params: { id: post.id, status: 'invalid' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("Invalid status selected.")
      expect(post.reload).to be_active
    end

    it "handles unexpected failure" do
      post = create(:post, status: :active)
      login_as(post.user)
      post.update_columns(board_id: 0) # rubocop:disable Rails/SkipsModelValidations
      expect(post.reload).not_to be_valid
      put :update, params: { id: post.id, status: 'abandoned' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error][:message]).to eq('Status could not be updated.')
      expect(post.reload.status).not_to eq(:abandoned)
    end

    it "marks read after completed" do
      post = nil
      Timecop.freeze(1.day.ago) do
        post = create(:post)
        login_as(post.user)
        post.mark_read(post.user)
      end
      put :update, params: { id: post.id, status: 'complete' }
      post = Post.find(post.id)
      expect(post.last_read(post.user)).to be_the_same_time_as(post.tagged_at)
    end

    Post.statuses.each_key do |status|
      context "to #{status}" do
        let(:post) { create(:post) }

        it "works for creator" do
          login_as(post.user)
          put :update, params: { id: post.id, status: status }
          expect(response).to redirect_to(post_url(post))
          expect(flash[:success]).to eq("Post has been marked #{status}.")
          expect(post.reload.send("#{status}?")).to eq(true)
        end

        it "works for coauthor" do
          reply = create(:reply, post: post)
          login_as(reply.user)
          put :update, params: { id: post.id, status: status }
          expect(response).to redirect_to(post_url(post))
          expect(flash[:success]).to eq("Post has been marked #{status}.")
          expect(post.reload.send("#{status}?")).to eq(true)
        end

        it "works for admin" do
          login_as(create(:admin_user))
          put :update, params: { id: post.id, status: status }
          expect(response).to redirect_to(post_url(post))
          expect(flash[:success]).to eq("Post has been marked #{status}.")
          expect(post.reload.send("#{status}?")).to eq(true)
        end
      end
    end

    context "with an old thread" do
      [:hiatus, :active].each do |status|
        context "to #{status}" do
          time = 2.months.ago
          let(:post) { create(:post, created_at: time, updated_at: time) }
          let(:reply) { create(:reply, post: post, created_at: time, updated_at: time) }

          before (:each) { reply }

          it "works for creator" do
            login_as(post.user)
            expect(post.reload.tagged_at).to be_the_same_time_as(time)
            put :update, params: { id: post.id, status: status }
            expect(response).to redirect_to(post_url(post))
            expect(flash[:success]).to eq("Post has been marked #{status}.")
            expect(post.reload.send(:on_hiatus?)).to eq(true)
            expect(post.reload.send(:hiatus?)).to eq(status == :hiatus)
          end

          it "works for coauthor" do
            login_as(reply.user)
            expect(post.reload.tagged_at).to be_the_same_time_as(time)
            put :update, params: { id: post.id, status: status }
            expect(response).to redirect_to(post_url(post))
            expect(flash[:success]).to eq("Post has been marked #{status}.")
            expect(post.reload.send(:on_hiatus?)).to eq(true)
            expect(post.reload.send(:hiatus?)).to eq(status == :hiatus)
          end

          it "works for admin" do
            login_as(create(:admin_user))
            expect(post.reload.tagged_at).to be_the_same_time_as(time)
            put :update, params: { id: post.id, status: status }
            expect(response).to redirect_to(post_url(post))
            expect(flash[:success]).to eq("Post has been marked #{status}.")
            expect(post.reload.send(:on_hiatus?)).to eq(true)
            expect(post.reload.send(:hiatus?)).to eq(status == :hiatus)
          end
        end
      end
    end
  end

  context "author lock" do
    let(:post) { create(:post, authors_locked: false) }

    it "requires permission" do
      login
      put :update, params: { id: post.id, authors_locked: 'true' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
      expect(post.reload).not_to be_authors_locked
    end

    it "works for creator" do
      login_as(post.user)
      put :update, params: { id: post.id, authors_locked: 'true' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post has been locked to current authors.")
      expect(post.reload).to be_authors_locked

      put :update, params: { id: post.id, authors_locked: 'false' }
      expect(flash[:success]).to eq("Post has been unlocked from current authors.")
      expect(post.reload).not_to be_authors_locked
    end

    it "works for coauthor" do
      reply = create(:reply, post: post)
      login_as(reply.user)
      put :update, params: { id: post.id, authors_locked: 'true' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post has been locked to current authors.")
      expect(post.reload).to be_authors_locked

      put :update, params: { id: post.id, authors_locked: 'false' }
      expect(flash[:success]).to eq("Post has been unlocked from current authors.")
      expect(post.reload).not_to be_authors_locked
    end

    it "works for admin" do
      login_as(create(:admin_user))
      put :update, params: { id: post.id, authors_locked: 'true' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post has been locked to current authors.")
      expect(post.reload).to be_authors_locked

      put :update, params: { id: post.id, authors_locked: 'false' }
      expect(flash[:success]).to eq("Post has been unlocked from current authors.")
      expect(post.reload).not_to be_authors_locked
    end

    it "handles unexpected failure" do
      post = create(:post)
      login_as(post.user)
      post.update_columns(board_id: 0) # rubocop:disable Rails/SkipsModelValidations
      expect(post.reload).not_to be_valid
      put :update, params: { id: post.id, authors_locked: 'true' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error][:message]).to eq('Post could not be updated.')
      expect(post.reload).not_to be_authors_locked
    end
  end

  context "mark hidden" do
    it "marks hidden" do
      post = create(:post)
      reply = create(:reply, post: post)
      user = create(:user)
      post.mark_read(user, at_time: post.read_time_for([reply]))
      time_read = post.reload.last_read(user)

      login_as(user)
      expect(post.ignored_by?(user)).not_to eq(true)

      put :update, params: { id: post.id, hidden: 'true' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post has been hidden")
      expect(post.reload.ignored_by?(user)).to eq(true)
      expect(post.last_read(user)).to be_the_same_time_as(time_read)
    end

    it "marks unhidden" do
      post = create(:post)
      reply = create(:reply, post: post)
      user = create(:user)
      login_as(user)
      post.mark_read(user, at_time: post.read_time_for([reply]))
      time_read = post.reload.last_read(user)

      post.ignore(user)
      expect(post.reload.ignored_by?(user)).to eq(true)

      put :update, params: { id: post.id, hidden: 'false' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post has been unhidden")
      expect(post.reload.ignored_by?(user)).not_to eq(true)
      expect(post.last_read(user)).to be_the_same_time_as(time_read)
    end
  end

  context "preview" do
    it "handles tags appropriately in memory and storage" do
      user = create(:user)
      login_as(user)

      setting = create(:setting)
      rems = create(:setting)
      dupes = create(:setting, name: 'dupesetting')
      warning = create(:content_warning)
      remw = create(:content_warning)
      dupew = create(:content_warning, name: 'dupewarning')
      label = create(:label)
      reml = create(:label)
      dupel = create(:label, name: 'dupelabel')

      post = create(:post, user: user, settings: [setting, rems], content_warnings: [warning, remw], labels: [label, reml])
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)

      # for each type: keep one, remove one, create one, existing one
      setting_ids = [setting.id, '_setting', '_dupesetting']
      warning_ids = [warning.id, '_warning', '_dupewarning']
      label_ids = [label.id, '_label', '_dupelabel']
      put :update, params: {
        id: post.id,
        button_preview: true,
        post: {
          setting_ids: setting_ids,
          content_warning_ids: warning_ids,
          label_ids: label_ids,
        },
      }
      expect(response).to render_template(:preview)
      post = assigns(:post)

      expect(post.settings.size).to eq(2)
      expect(post.content_warnings.size).to eq(2)
      expect(post.labels.size).to eq(2)
      expect(assigns(:settings).map(&:name)).to match_array([setting.name, 'setting', 'dupesetting'])
      expect(assigns(:content_warnings).map(&:name)).to match_array([warning.name, 'warning', 'dupewarning'])
      expect(assigns(:labels).map(&:name)).to match_array([label.name, 'label', 'dupelabel'])
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)
      expect(PostTag.where(post: post, tag: [setting, warning, label]).count).to eq(3)
      expect(PostTag.where(post: post, tag: [dupes, dupew, dupel]).count).to eq(0)
      expect(PostTag.where(post: post, tag: [reml, remw, rems]).count).to eq(3)
    end

    it "sets expected variables" do
      Post.auditing_enabled = true
      user = create(:user)
      login_as(user)
      post = create(:post, user: user, subject: 'old', content: 'example')
      setting1 = create(:setting)
      setting2 = create(:setting)
      warning1 = create(:content_warning)
      warning2 = create(:content_warning)
      label1 = create(:label)
      label2 = create(:label)
      char1 = create(:character, user: user)
      char2 = create(:template_character, user: user)
      icon = create(:icon, user: user)
      calias = create(:alias, character: char1)
      coauthor = create(:user)
      viewer = create(:user)
      expect(controller).to receive(:editor_setup).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original
      put :update, params: {
        id: post.id,
        button_preview: true,
        post: {
          subject: 'test',
          content: 'orign',
          character_id: char1.id,
          icon_id: icon.id,
          character_alias_id: calias.id,
          setting_ids: [setting1.id, "_ #{setting2.name}", '_other'],
          content_warning_ids: [warning1.id, "_#{warning2.name}", '_other'],
          label_ids: [label1.id, "_#{label2.name}", '_other'],
          unjoined_author_ids: [coauthor.id],
          viewer_ids: [viewer.id],
        },
      }
      expect(response).to render_template(:preview)
      expect(assigns(:written)).to be_an_instance_of(Post)
      expect(assigns(:written)).not_to be_a_new_record
      expect(assigns(:post)).to eq(assigns(:written))
      expect(assigns(:post).user).to eq(user)
      expect(assigns(:post).subject).to eq('test')
      expect(assigns(:post).content).to eq('orign')
      expect(assigns(:post).character).to eq(char1)
      expect(assigns(:post).icon).to eq(icon)
      expect(assigns(:post).character_alias).to eq(calias)
      expect(assigns(:page_title)).to eq('Previewing: test')
      expect(assigns(:audits)).to eq({ post: 1 })

      # editor_setup:
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(controller.gon.editor_user[:username]).to eq(user.username)
      expect(assigns(:author_ids)).to match_array([coauthor.id])
      # ensure it doesn't change the actual post:
      expect(post.reload.tagging_authors).to match_array([user])
      expect(post.viewer_ids).to be_empty
      expect(assigns(:viewer_ids)).to eq([viewer.id.to_s])

      # templates
      templates = assigns(:templates)
      expect(templates.length).to eq(3)
      thread_chars = templates.first
      expect(thread_chars.name).to eq('Thread characters')
      expect(thread_chars.plucked_characters).to eq([[char1.id, char1.name]])
      template_chars = templates[1]
      expect(template_chars).to eq(char2.template)
      templateless = templates.last
      expect(templateless.name).to eq('Templateless')
      expect(templateless.plucked_characters).to eq([[char1.id, char1.name]])

      # tags
      expect(assigns(:post).settings.size).to eq(0)
      expect(assigns(:post).content_warnings.size).to eq(0)
      expect(assigns(:post).labels.size).to eq(0)
      expect(assigns(:settings).map(&:id_for_select)).to match_array([setting1.id, setting2.id, '_other'])
      expect(assigns(:content_warnings).map(&:id_for_select)).to match_array([warning1.id, warning2.id, '_other'])
      expect(assigns(:labels).map(&:id_for_select)).to match_array([label1.id, label2.id, '_other'])
      expect(Setting.count).to eq(2)
      expect(ContentWarning.count).to eq(2)
      expect(Label.count).to eq(2)
      expect(PostTag.count).to eq(0)

      # in storage
      post = assigns(:post).reload
      expect(post.user).to eq(user)
      expect(post.subject).to eq('old')
      expect(post.content).to eq('example')
      expect(post.character).to be_nil
      expect(post.icon).to be_nil
      expect(post.character_alias).to be_nil
      Post.auditing_enabled = false
    end

    it "does not crash without arguments" do
      user = create(:user)
      login_as(user)
      post = create(:post, user: user)
      put :update, params: { id: post.id, button_preview: true }
      expect(response).to render_template(:preview)
      expect(assigns(:written).user).to eq(user)
    end

    it "saves a draft" do
      skip "TODO"
    end

    it "does not create authors or viewers" do
      user = create(:user)
      login_as(user)

      coauthor = create(:user)
      board = create(:board, creator: user, authors_locked: true)
      post = create(:post, user: user, board: board, authors_locked: true, privacy: :access_list)

      expect {
        put :update, params: {
          id: post.id,
          button_preview: true,
          post: {
            unjoined_author_ids: [coauthor.id],
            viewer_ids: [coauthor.id, create(:user).id],
          },
        }
      }.not_to change { [Post::Author.count, PostViewer.count, BoardAuthor.count] }

      expect(flash[:error]).to be_nil
      expect(assigns(:page_title)).to eq('Previewing: ' + assigns(:post).subject.to_s)
    end

    skip "TODO"
  end

  context "make changes" do
    it "creates new tags if needed" do
      user = create(:user)
      login_as(user)

      setting = create(:setting)
      rems = create(:setting)
      dupes = create(:setting, name: 'dupesetting')
      warning = create(:content_warning)
      remw = create(:content_warning)
      dupew = create(:content_warning, name: 'dupewarning')
      label = create(:label)
      reml = create(:label)
      dupel = create(:label, name: 'dupelabel')

      post = create(:post, user: user, settings: [setting, rems], content_warnings: [warning, remw], labels: [label, reml])
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)

      # for each type: keep one, remove one, create one, existing one
      setting_ids = [setting.id, '_setting', '_dupesetting']
      warning_ids = [warning.id, '_warning', '_dupewarning']
      label_ids = [label.id, '_label', '_dupelabel']
      put :update, params: {
        id: post.id,
        post: {
          setting_ids: setting_ids,
          content_warning_ids: warning_ids,
          label_ids: label_ids,
        },
      }
      expect(response).to redirect_to(post_url(post))
      post = assigns(:post)

      expect(post.settings.size).to eq(3)
      expect(post.content_warnings.size).to eq(3)
      expect(post.labels.size).to eq(3)
      expect(post.settings.map(&:name)).to match_array([setting.name, 'setting', 'dupesetting'])
      expect(post.content_warnings.map(&:name)).to match_array([warning.name, 'warning', 'dupewarning'])
      expect(post.labels.map(&:name)).to match_array([label.name, 'label', 'dupelabel'])
      expect(Setting.count).to eq(4)
      expect(ContentWarning.count).to eq(4)
      expect(Label.count).to eq(4)
      expect(PostTag.count).to eq(9)
      expect(PostTag.where(post: post, tag: [setting, warning, label]).count).to eq(3)
      expect(PostTag.where(post: post, tag: [dupes, dupew, dupel]).count).to eq(3)
      expect(PostTag.where(post: post, tag: [reml, remw, rems]).count).to eq(0)
    end

    it "uses extant tags if available" do
      user = create(:user)
      login_as(user)
      post = create(:post, user: user)
      setting_ids = ['_setting']
      setting = create(:setting, name: 'setting')
      warning_ids = ['_warning']
      warning = create(:content_warning, name: 'warning')
      label_ids = ['_label']
      tag = create(:label, name: 'label')
      put :update, params: {
        id: post.id,
        post: { setting_ids: setting_ids, content_warning_ids: warning_ids, label_ids: label_ids },
      }
      expect(response).to redirect_to(post_url(post))
      post = assigns(:post)
      expect(post.settings).to eq([setting])
      expect(post.content_warnings).to eq([warning])
      expect(post.labels).to eq([tag])
    end

    it "correctly updates when adding new authors" do
      user = create(:user)
      other_user = create(:user)
      login_as(user)
      post = create(:post, user: user)

      time = 5.minutes.from_now
      Timecop.freeze(time) do
        expect {
          put :update, params: {
            id: post.id,
            post: {
              unjoined_author_ids: [other_user.id],
            },
          }
        }.to change { Post::Author.count }.by(1)
      end

      expect(response).to redirect_to(post_url(post))
      post.reload
      expect(post.tagging_authors).to match_array([user, other_user])

      # doesn't change joined time or invited status when inviting main user
      main_author = post.author_for(user)
      expect(main_author.can_owe).to eq(true)
      expect(main_author.joined).to eq(true)
      expect(main_author.joined_at).to be_the_same_time_as(post.created_at)

      # doesn't set joined time but does set invited status when inviting new user
      new_author = post.author_for(other_user)
      expect(new_author.can_owe).to eq(true)
      expect(new_author.joined).to eq(false)
      expect(new_author.joined_at).to be_nil
    end

    it "correctly updates when removing authors" do
      user = create(:user)
      invited_user = create(:user)
      joined_user = create(:user)

      login_as(user)
      time = 5.minutes.ago
      post = reply = nil
      Timecop.freeze(time) do
        post = create(:post, user: user, unjoined_authors: [invited_user])
        reply = create(:reply, user: joined_user, post: post)
      end

      post.reload
      expect(post.authors).to match_array([user, invited_user, joined_user])
      expect(post.joined_authors).to match_array([user, joined_user])

      post_author = post.author_for(user)
      expect(post_author.joined).to eq(true)
      expect(post_author.joined_at).to be_the_same_time_as(post.created_at)

      invited_post_author = post.author_for(invited_user)
      expect(invited_post_author.joined).to eq(false)

      joined_post_author = post.author_for(joined_user)
      expect(joined_post_author.joined).to eq(true)
      expect(joined_post_author.joined_at).to be_the_same_time_as(reply.created_at)

      put :update, params: {
        id: post.id,
        post: {
          unjoined_author_ids: [''],
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq('Your post has been updated.')

      post.reload
      expect(post.authors).to match_array([user, joined_user])
      expect(post.joined_authors).to match_array([user, joined_user])
      expect(post.tagging_authors).to match_array([user, joined_user])

      post_author.reload
      expect(post_author.can_owe).to eq(true)
      expect(post_author.joined).to eq(true)
      expect(post_author.joined_at).to be_the_same_time_as(post.created_at)

      expect(post.author_for(invited_user)).to be_nil

      joined_post_author.reload
      expect(joined_post_author.can_owe).to eq(true)
      expect(joined_post_author.joined).to eq(true)
      expect(joined_post_author.joined_at).to be_the_same_time_as(reply.created_at)
    end

    it "updates board cameos if necessary" do
      user = create(:user)
      other_user = create(:user)
      third_user = create(:user)
      login_as(user)
      board = create(:board, creator: user, writers: [other_user])
      post = create(:post, user: user, board: board)
      put :update, params: {
        id: post.id,
        post: {
          unjoined_author_ids: [other_user.id, third_user.id],
        },
      }
      post.reload
      board.reload
      expect(post.tagging_authors).to match_array([user, other_user, third_user])
      expect(board.cameos).to match_array([third_user])
    end

    it "does not add to cameos of open boards" do
      user = create(:user)
      other_user = create(:user)
      login_as(user)
      board = create(:board)
      expect(board.cameos).to be_empty
      post = create(:post, user: user, board: board)
      put :update, params: {
        id: post.id,
        post: {
          unjoined_author_ids: [other_user.id],
        },
      }
      post.reload
      board.reload
      expect(post.tagging_authors).to match_array([user, other_user])
      expect(board.cameos).to be_empty
    end

    it "orders tags" do
      user = create(:user)
      login_as(user)
      post = create(:post, user: user)
      setting2 = create(:setting)
      setting3 = create(:setting)
      setting1 = create(:setting)
      warning1 = create(:content_warning)
      warning3 = create(:content_warning)
      warning2 = create(:content_warning)
      tag3 = create(:label)
      tag1 = create(:label)
      tag2 = create(:label)
      put :update, params: {
        id: post.id,
        post: {
          setting_ids: [setting1, setting2, setting3].map(&:id),
          content_warning_ids: [warning1, warning2, warning3].map(&:id),
          label_ids: [tag1, tag2, tag3].map(&:id),
        },
      }
      expect(response).to redirect_to(post_url(post))
      post = assigns(:post)
      expect(post.settings).to eq([setting1, setting2, setting3])
      expect(post.content_warnings).to eq([warning1, warning2, warning3])
      expect(post.labels).to eq([tag1, tag2, tag3])
    end

    it "requires valid update" do
      setting = create(:setting)
      rems = create(:setting)
      dupes = create(:setting, name: 'dupesetting')
      warning = create(:content_warning)
      remw = create(:content_warning)
      dupew = create(:content_warning, name: 'dupewarning')
      label = create(:label)
      reml = create(:label)
      dupel = create(:label, name: 'dupelabel')

      user = create(:user)
      login_as(user)

      post = create(:post, user: user, settings: [setting, rems], content_warnings: [warning, remw], labels: [label, reml])
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)

      char1 = create(:character, user: user)
      char2 = create(:template_character, user: user)

      coauthor = create(:user)

      expect(controller).to receive(:editor_setup).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      # for each type: keep one, remove one, create one, existing one
      setting_ids = [setting.id, '_setting', '_dupesetting']
      warning_ids = [warning.id, '_warning', '_dupewarning']
      label_ids = [label.id, '_label', '_dupelabel']
      put :update, params: {
        id: post.id,
        post: {
          subject: '',
          setting_ids: setting_ids,
          content_warning_ids: warning_ids,
          label_ids: label_ids,
          unjoined_author_ids: [coauthor.id],
        },
      }

      expect(response).to render_template(:edit)
      expect(flash[:error][:message]).to eq("Your post could not be saved because of the following problems:")
      expect(post.reload.subject).not_to be_empty

      # editor_setup:
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(controller.gon.editor_user[:username]).to eq(user.username)
      expect(assigns(:author_ids)).to match_array([coauthor.id])

      # templates
      templates = assigns(:templates)
      expect(templates.length).to eq(2)
      template_chars = templates.first
      expect(template_chars).to eq(char2.template)
      templateless = templates.last
      expect(templateless.name).to eq('Templateless')
      expect(templateless.plucked_characters).to eq([[char1.id, char1.name]])

      # tags change only in memory when save fails
      post = assigns(:post)
      expect(post.settings.size).to eq(3)
      expect(post.content_warnings.size).to eq(3)
      expect(post.labels.size).to eq(3)
      expect(post.settings.map(&:name)).to match_array([setting.name, 'setting', 'dupesetting'])
      expect(post.content_warnings.map(&:name)).to match_array([warning.name, 'warning', 'dupewarning'])
      expect(post.labels.map(&:name)).to match_array([label.name, 'label', 'dupelabel'])
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)
      expect(PostTag.where(post: post, tag: [setting, warning, label]).count).to eq(3)
      expect(PostTag.where(post: post, tag: [dupes, dupew, dupel]).count).to eq(0)
      expect(PostTag.where(post: post, tag: [reml, remw, rems]).count).to eq(3)
    end

    it "works" do
      user = create(:user)
      removed_author = create(:user)
      joined_author = create(:user)

      post = create(:post, user: user, unjoined_authors: [removed_author])
      create(:reply, user: joined_author, post: post)

      newcontent = post.content + 'new'
      newsubj = post.subject + 'new'
      login_as(user)
      board = create(:board)
      section = create(:board_section, board: board)
      char = create(:character, user: user)
      calias = create(:alias, character_id: char.id)
      icon = create(:icon, user: user)
      viewer = create(:user)
      setting = create(:setting)
      warning = create(:content_warning)
      tag = create(:label)
      coauthor = create(:user)

      post.reload
      expect(post.tagging_authors).to match_array([user, removed_author, joined_author])
      expect(post.joined_authors).to match_array([user, joined_author])
      expect(post.viewers).to be_empty

      put :update, params: {
        id: post.id,
        post: {
          content: newcontent,
          subject: newsubj,
          description: 'desc',
          board_id: board.id,
          section_id: section.id,
          character_id: char.id,
          character_alias_id: calias.id,
          icon_id: icon.id,
          privacy: :access_list,
          viewer_ids: [viewer.id],
          setting_ids: [setting.id],
          content_warning_ids: [warning.id],
          label_ids: [tag.id],
          unjoined_author_ids: [coauthor.id],
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Your post has been updated.")

      post.reload
      expect(post.content).to eq(newcontent)
      expect(post.subject).to eq(newsubj)
      expect(post.description).to eq('desc')
      expect(post.board_id).to eq(board.id)
      expect(post.section_id).to eq(section.id)
      expect(post.character_id).to eq(char.id)
      expect(post.character_alias_id).to eq(calias.id)
      expect(post.icon_id).to eq(icon.id)
      expect(post).to be_privacy_access_list
      expect(post.viewers).to match_array([viewer])
      expect(post.settings).to eq([setting])
      expect(post.content_warnings).to eq([warning])
      expect(post.labels).to eq([tag])
      expect(post.reload).to be_visible_to(viewer)
      expect(post.reload).not_to be_visible_to(create(:user))
      expect(post.tagging_authors).to match_array([user, joined_author, coauthor])
      expect(post.joined_authors).to match_array([user, joined_author])
      expect(post.authors).to match_array([user, coauthor, joined_author])
    end

    it "does not allow coauthors to edit post text" do
      skip "Is not currently implemented on saving data"
      user = create(:user)
      coauthor = create(:user)
      login_as(coauthor)
      post = create(:post, user: user, authors: [user, coauthor], authors_locked: true)
      put :update, params: {
        id: post.id,
        post: {
          content: "newtext",
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
    end
  end

  context "metadata" do
    it "allows coauthors" do
      coauthor = create(:user)
      login_as(coauthor)
      post = create(:post, subject: "test subject")
      create(:reply, post: post, user: coauthor)
      put :update, params: {
        id: post.id,
        post: {
          subject: "new subject",
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Your post has been updated.")
      post.reload
      expect(post.subject).to eq("new subject")
    end

    it "allows invited coauthors before they reply" do
      user = create(:user)
      coauthor = create(:user)
      login_as(coauthor)
      post = create(:post, user: user, authors: [user, coauthor], authors_locked: true, subject: "test subject")
      put :update, params: {
        id: post.id,
        post: {
          subject: "new subject",
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Your post has been updated.")
      post.reload
      expect(post.subject).to eq("new subject")
    end

    it "does not allow non-coauthors" do
      login
      post = create(:post, subject: "test subject")
      put :update, params: {
        id: post.id,
        post: {
          subject: "new subject",
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
      post.reload
      expect(post.subject).to eq("test subject")
    end
  end

  context "notes" do
    it "updates if there are no other changes" do
      post = create(:post)
      login_as(post.user)
      expect(post.author_for(post.user).private_note).to be_nil
      put :update, params: {
        id: post.id,
        post: {
          private_note: 'look a note!',
        },
      }
      expect(Post.find_by_id(post.id).author_for(post.user).private_note).not_to be_nil
    end

    it "updates with other changes" do
      post = create(:post, content: 'old')
      login_as(post.user)
      expect(post.author_for(post.user).private_note).to be_nil
      put :update, params: {
        id: post.id,
        post: {
          private_note: 'look a note!',
          content: 'new',
        },
      }
      expect(Post.find_by_id(post.id).author_for(post.user).private_note).not_to be_nil
      expect(post.reload.content).to eq('new')
    end

    it "updates with coauthor" do
      post = create(:post)
      reply = create(:reply, post: post)
      login_as(reply.user)
      expect(post.author_for(reply.user).private_note).to be_nil
      put :update, params: {
        id: post.id,
        post: {
          private_note: 'look a note!',
        },
      }
      expect(Post.find_by_id(post.id).author_for(reply.user).private_note).not_to be_nil
    end
  end

  context "with blocks" do
    let(:user) { create(:user) }
    let(:blocked) { create(:user) }
    let(:blocking) { create(:user) }
    let(:other_user) { create(:user) }

    before(:each) do
      create(:block, blocking_user: user, blocked_user: blocked, hide_me: :posts)
      create(:block, blocking_user: blocking, blocked_user: user, hide_them: :posts)
    end

    it "regenerates blocked and hidden posts for poster" do
      post = create(:post, user: user, authors_locked: false, unjoined_authors: [other_user])

      expect(blocking.hidden_posts).to be_empty
      expect(blocked.blocked_posts).to be_empty

      login_as(user)

      put :update, params: {
        id: post.id,
        post: { authors_locked: true },
      }

      expect(Rails.cache.exist?(Block.cache_string_for(blocking.id, 'hidden'))).to be(false)
      expect(Rails.cache.exist?(Block.cache_string_for(blocked.id, 'blocked'))).to be(false)

      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])
    end

    it "regenerates blocked and hidden posts for coauthor" do
      post = create(:post, user: other_user, authors_locked: false, unjoined_authors: [user])

      expect(blocking.hidden_posts).to be_empty
      expect(blocked.blocked_posts).to be_empty

      login_as(other_user)

      put :update, params: {
        id: post.id,
        post: { authors_locked: true },
      }

      expect(Rails.cache.exist?(Block.cache_string_for(blocking.id, 'hidden'))).to be(false)
      expect(Rails.cache.exist?(Block.cache_string_for(blocked.id, 'blocked'))).to be(false)

      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])
    end

    it "regenerates blocked and hidden posts for new coauthor" do
      post = create(:post, user: other_user, authors_locked: true)

      expect(blocking.hidden_posts).to be_empty
      expect(blocked.blocked_posts).to be_empty

      login_as(other_user)

      put :update, params: {
        id: post.id,
        post: {
          unjoined_author_ids: [user.id],
        },
      }

      expect(Rails.cache.exist?(Block.cache_string_for(blocking.id, 'hidden'))).to be(false)
      expect(Rails.cache.exist?(Block.cache_string_for(blocked.id, 'blocked'))).to be(false)

      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])
    end

    it "regenerates blocked and hidden posts for removed coauthor" do
      post = create(:post, user: other_user, unjoined_authors: [user], authors_locked: true)

      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])

      login_as(other_user)

      put :update, params: {
        id: post.id,
        post: {
          unjoined_author_ids: [''],
        },
      }

      post.reload
      expect(post.unjoined_authors).to be_empty

      expect(Rails.cache.exist?(Block.cache_string_for(blocking.id, 'hidden'))).to be(false)
      expect(Rails.cache.exist?(Block.cache_string_for(blocked.id, 'blocked'))).to be(false)

      expect(blocking.hidden_posts).to be_empty
      expect(blocked.blocked_posts).to be_empty
    end
  end
end
