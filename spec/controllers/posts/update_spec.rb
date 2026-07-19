RSpec.describe PostsController, 'PUT update' do
  let(:user) { create(:user) }
  let(:coauthor) { create(:user) }
  let(:joined_user) { create(:user) }
  let(:invited_user) { create(:user) }
  let(:viewer) { create(:user) }
  let(:admin) { create(:admin_user) }

  let(:board) { create(:board) }
  let(:post) { create(:post, board: board) }
  let(:reply) { create(:reply, post: post, user: coauthor) }
  let(:private_post) { create(:post, privacy: :private) }
  let(:user_post) { create(:post, user: user, board: board) }

  let(:setting) { create(:setting, name: 'setting') }
  let(:removed_setting) { create(:setting) }
  let(:duplicate_setting) { create(:setting, name: 'dupesetting') }
  let(:warning) { create(:content_warning, name: 'warning') }
  let(:removed_warning) { create(:content_warning) }
  let(:duplicate_warning) { create(:content_warning, name: 'dupewarning') }
  let(:label) { create(:label, name: 'label') }
  let(:removed_label) { create(:label) }
  let(:duplicate_label) { create(:label, name: 'dupelabel') }
  let(:regular_tags) { [setting, warning, label] }
  let(:duplicate_tags) { [duplicate_setting, duplicate_warning, duplicate_label] }
  let(:removed_tags) { [removed_setting, removed_warning, removed_label] }

  let(:setting_ids) { [setting.id, '_newsetting', '_dupesetting'] }
  let(:warning_ids) { [warning.id, '_newwarning', '_dupewarning'] }
  let(:label_ids) { [label.id, '_newlabel', '_dupelabel'] }
  let(:settings_select) { [setting.id, duplicate_setting.id, '_newsetting'] }
  let(:warnings_select) { [warning.id, duplicate_warning.id, '_newwarning'] }
  let(:labels_select) { [label.id, duplicate_label.id, '_newlabel'] }

  let(:templateless_character) { create(:character, user: user) }
  let(:templated_character) { create(:template_character, user: user) }
  let(:character_alias) { create(:alias, character: templateless_character) }
  let(:icon) { create(:icon, user: user) }

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
    login_as(user)

    put :update, params: { id: private_post.id }
    expect(response).to redirect_to(continuities_url)
    expect(flash[:error]).to eq("You do not have permission to view this post.")
  end

  it "requires notes from moderators" do
    login_as(admin)
    put :update, params: { id: post.id }
    expect(response).to render_template(:edit)
    expect(flash[:error]).to eq('You must provide a reason for your moderator edit.')
  end

  it "does not require note from coauthors" do
    post = create(:post, privacy: :access_list, authors: [user], viewers: [user])
    login_as(user)
    put :update, params: { id: post.id }
    expect(flash[:success]).not_to be_nil
    expect(flash[:error]).not_to eq('You must provide a reason for your moderator edit.')
  end

  it "stores note from moderators" do
    Post.auditing_enabled = true
    login_as(admin)
    put :update, params: {
      id: post.id,
      post: { description: 'b', audit_comment: 'note' },
    }
    expect(flash[:success]).to eq("Post updated.")
    expect(post.reload.description).to eq('b')
    expect(post.audits.last.comment).to eq('note')
    Post.auditing_enabled = false
  end

  context "mark unread" do
    let(:unread_reply) { build(:reply, post: post) }

    before(:each) { login_as(user) }

    # rubocop:disable RSpec/RepeatedExample
    it "requires valid at_id" do
      skip "TODO does not notify"
    end

    it "requires post's at_id" do
      skip "TODO does not notify"
    end
    # rubocop:enable RSpec/RepeatedExample

    context "with at_id" do
      before(:each) do
        Timecop.freeze(post.created_at + 1.minute) do
          unread_reply.save!
          create(:reply, post: post)
        end

        Timecop.freeze(post.created_at + 2.minutes) { post.mark_read(user) }
      end

      it "works" do
        put :update, params: { id: post.id, unread: true, at_id: unread_reply.id }

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("Post has been marked as read until reply ##{unread_reply.id}.")
        expect(post.reload.last_read(user)).to be_the_same_time_as(unread_reply.created_at - 1.second)
        expect(post.reload.first_unread_for(user)).to eq(unread_reply)
      end

      it "works when ignored" do
        Timecop.freeze(post.created_at + 2.minutes) { post.ignore(user) }
        expect(post.reload.first_unread_for(user)).to be_nil

        put :update, params: { id: post.id, unread: true, at_id: unread_reply.id }

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("Post has been marked as read until reply ##{unread_reply.id}.")
        expect(post.reload.last_read(user)).to be_the_same_time_as(unread_reply.created_at - 1.second)
        expect(post.reload.first_unread_for(user)).to eq(unread_reply)
        expect(post).to be_ignored_by(user)
      end
    end

    context "without at_id" do
      before(:each) { post.mark_read(user) }

      it "works" do
        expect(post.reload.send(:view_for, user)).not_to be_nil

        put :update, params: { id: post.id, unread: true }

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("Post has been marked as unread")
        expect(post.reload.first_unread_for(user)).to eq(post)
      end

      it "works when ignored" do
        post.ignore(user)
        expect(post.reload.first_unread_for(user)).to be_nil

        put :update, params: { id: post.id, unread: true }

        expect(response).to redirect_to(unread_posts_url)
        expect(flash[:success]).to eq("Post has been marked as unread")
        expect(post.reload.first_unread_for(user)).to eq(post)
      end
    end
  end

  context "change status" do
    before(:each) { login_as(user) }

    it "requires permission" do
      put :update, params: { id: post.id, status: 'complete' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:error]).to eq("You do not have permission to modify this post.")
      expect(post.reload).to be_active
    end

    it "requires valid status" do
      put :update, params: { id: user_post.id, status: 'invalid' }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error]).to eq("Invalid status selected.")
      expect(user_post.reload).to be_active
    end

    it "handles unexpected failure" do
      # associate with section from a different board (invalid)
      user_post.update_columns(section_id: create(:board_section).id) # rubocop:disable Rails/SkipsModelValidations
      put :update, params: { id: user_post.id, status: 'abandoned' }
      expect(response).to redirect_to(post_url(user_post))
      expect(flash[:error][:message]).to eq('Status could not be updated because of the following problems:')
      expect(user_post.reload.status).not_to eq(:abandoned)
    end

    it "marks read after completed" do
      post = build(:post, user: user)

      Timecop.freeze(1.day.ago) do
        post.save!
        post.mark_read(user)
      end

      put :update, params: { id: post.id, status: 'complete' }

      post.reload
      expect(post.last_read(post.user)).to be_the_same_time_as(post.tagged_at)
    end

    Post.statuses.each_key do |status|
      context "to #{status}" do
        it "works for creator" do
          login_as(post.user)
          put :update, params: { id: post.id, status: status }
          expect(response).to redirect_to(post_url(post))
          expect(flash[:success]).to eq("Post has been marked #{status}.")
          expect(post.reload.send(:"#{status}?")).to eq(true)
        end

        it "works for coauthor" do
          login_as(reply.user)
          put :update, params: { id: post.id, status: status }
          expect(response).to redirect_to(post_url(post))
          expect(flash[:success]).to eq("Post has been marked #{status}.")
          expect(post.reload.send(:"#{status}?")).to eq(true)
        end

        it "works for admin" do
          login_as(admin)
          put :update, params: { id: post.id, status: status }
          expect(response).to redirect_to(post_url(post))
          expect(flash[:success]).to eq("Post has been marked #{status}.")
          expect(post.reload.send(:"#{status}?")).to eq(true)
        end
      end
    end

    context "with an old thread" do
      [:hiatus, :active].each do |status|
        context "to #{status}" do
          let(:time) { 2.months.ago }
          let(:post) { Timecop.freeze(time) { create(:post) } }
          let!(:reply) { Timecop.freeze(time) { create(:reply, post: post) } }

          it "works for creator" do
            login_as(post.user)
            put :update, params: { id: post.id, status: status }
            expect(response).to redirect_to(post_url(post))
            expect(flash[:success]).to eq("Post has been marked #{status}.")
            expect(post.reload.send(:on_hiatus?)).to eq(true)
            expect(post.reload.send(:hiatus?)).to eq(status == :hiatus)
          end

          it "works for coauthor" do
            login_as(reply.user)
            put :update, params: { id: post.id, status: status }
            expect(response).to redirect_to(post_url(post))
            expect(flash[:success]).to eq("Post has been marked #{status}.")
            expect(post.reload.send(:on_hiatus?)).to eq(true)
            expect(post.reload.send(:hiatus?)).to eq(status == :hiatus)
          end

          it "works for admin" do
            login_as(admin)
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
    context "locking" do
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
      end

      it "works for coauthor" do
        login_as(reply.user)
        put :update, params: { id: post.id, authors_locked: 'true' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:success]).to eq("Post has been locked to current authors.")
        expect(post.reload).to be_authors_locked
      end

      it "works for admin" do
        login_as(admin)
        put :update, params: { id: post.id, authors_locked: 'true' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:success]).to eq("Post has been locked to current authors.")
        expect(post.reload).to be_authors_locked
      end

      it "handles unexpected failure" do
        login_as(post.user)
        # associate with section from a different board (invalid)
        post.update_columns(section_id: create(:board_section).id) # rubocop:disable Rails/SkipsModelValidations
        expect(post.reload).not_to be_valid
        put :update, params: { id: post.id, authors_locked: 'true' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:error][:message]).to eq('Post could not be updated because of the following problems:')
        expect(post.reload).not_to be_authors_locked
      end
    end

    context "unlocking" do
      let(:post) { create(:post, authors_locked: true, unjoined_authors: [coauthor]) }
      let(:reply) { create(:reply, user: coauthor, post: post) }

      it "requires permission" do
        login
        put :update, params: { id: post.id, authors_locked: 'true' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:error]).to eq("You do not have permission to modify this post.")
        expect(post.reload).to be_authors_locked
      end

      it "works for creator" do
        login_as(post.user)
        put :update, params: { id: post.id, authors_locked: 'false' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:success]).to eq("Post has been unlocked from current authors.")
        expect(post.reload).not_to be_authors_locked
      end

      it "works for coauthor" do
        login_as(reply.user)
        put :update, params: { id: post.id, authors_locked: 'false' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:success]).to eq("Post has been unlocked from current authors.")
        expect(post.reload).not_to be_authors_locked
      end

      it "works for admin" do
        login_as(admin)
        put :update, params: { id: post.id, authors_locked: 'false' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:success]).to eq("Post has been unlocked from current authors.")
        expect(post.reload).not_to be_authors_locked
      end

      it "handles unexpected failure" do
        login_as(post.user)
        # associate with section from a different board (invalid)
        post.update_columns(section_id: create(:board_section).id) # rubocop:disable Rails/SkipsModelValidations
        put :update, params: { id: post.id, authors_locked: 'false' }
        expect(response).to redirect_to(post_url(post))
        expect(flash[:error][:message]).to eq('Post could not be updated because of the following problems:')
        expect(post.reload).to be_authors_locked
      end
    end
  end

  context "mark hidden" do
    let(:reply) { create(:reply, post: post) }
    let(:time_read) { post.reload.last_read(user) }

    before(:each) do
      login_as(user)
      post.mark_read(user, at_time: post.read_time_for([reply]))
    end

    it "marks hidden" do
      time_read

      put :update, params: { id: post.id, hidden: 'true' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post has been hidden")
      expect(post.reload.ignored_by?(user)).to eq(true)
      expect(post.last_read(user)).to be_the_same_time_as(time_read)
    end

    it "marks unhidden" do
      time_read
      post.ignore(user)

      put :update, params: { id: post.id, hidden: 'false' }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post has been unhidden")
      expect(post.reload.ignored_by?(user)).not_to eq(true)
      expect(post.last_read(user)).to be_the_same_time_as(time_read)
    end
  end

  context "preview" do
    before(:each) { login_as(user) }

    it "handles tags appropriately in memory and storage" do
      post = create(:post,
        user: user,
        settings: [setting, removed_setting],
        content_warnings: [warning, removed_warning],
        labels: [label, removed_label],
      )
      duplicate_tags

      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)

      # for each type: keep one, remove one, create one, existing one
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
      expect(assigns(:settings).map(&:id_for_select)).to match_array(settings_select)
      expect(assigns(:content_warnings).map(&:id_for_select)).to match_array(warnings_select)
      expect(assigns(:labels).map(&:id_for_select)).to match_array(labels_select)
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)
      expect(PostTag.where(post: post, tag: regular_tags).count).to eq(3)
      expect(PostTag.where(post: post, tag: duplicate_tags).count).to eq(0)
      expect(PostTag.where(post: post, tag: removed_tags).count).to eq(3)
    end

    it "sets expected variables" do
      Post.auditing_enabled = true
      post = create(:post, user: user, subject: 'old', content: 'example')
      icon = create(:icon, user: user)
      duplicate_tags
      templated_character

      expect(controller).to receive(:editor_setup).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      put :update, params: {
        id: post.id,
        button_preview: true,
        post: {
          subject: 'test',
          content: 'orign',
          character_id: templateless_character.id,
          icon_id: icon.id,
          character_alias_id: character_alias.id,
          setting_ids: setting_ids,
          content_warning_ids: warning_ids,
          label_ids: label_ids,
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
      expect(assigns(:post).character).to eq(templateless_character)
      expect(assigns(:post).icon).to eq(icon)
      expect(assigns(:post).character_alias).to eq(character_alias)
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
      templateless_select = [[templateless_character.id, templateless_character.name]]
      templates = assigns(:templates)
      expect(templates.length).to eq(3)
      expect(templates[0].name).to eq('Post characters')
      expect(templates[0].plucked_characters).to eq(templateless_select)
      expect(templates[1]).to eq(templated_character.template)
      expect(templates[2].name).to eq('Templateless')
      expect(templates[2].plucked_characters).to eq(templateless_select)

      # tags
      expect(assigns(:post).settings.size).to eq(0)
      expect(assigns(:post).content_warnings.size).to eq(0)
      expect(assigns(:post).labels.size).to eq(0)
      expect(assigns(:settings).map(&:id_for_select)).to match_array(settings_select)
      expect(assigns(:content_warnings).map(&:id_for_select)).to match_array(warnings_select)
      expect(assigns(:labels).map(&:id_for_select)).to match_array(labels_select)
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
      put :update, params: { id: user_post.id, button_preview: true }
      expect(response).to render_template(:preview)
      expect(assigns(:written).user).to eq(user)
    end

    it "saves a draft" do
      skip "TODO"
    end

    it "does not create authors or viewers" do
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
    before(:each) { login_as(user) }

    context "with tag changes" do
      it "creates new tags if needed" do
        post = create(:post,
          user: user,
          settings: [setting, removed_setting],
          content_warnings: [warning, removed_warning],
          labels: [label, removed_label],
        )
        duplicate_tags

        expect(Setting.count).to eq(3)
        expect(ContentWarning.count).to eq(3)
        expect(Label.count).to eq(3)
        expect(PostTag.count).to eq(6)

        # for each type: keep one, remove one, create one, existing one
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

        new_warning = ContentWarning.find_by(name: 'newwarning')
        expect(post.settings.size).to eq(3)
        expect(post.content_warnings.size).to eq(3)
        expect(post.labels.size).to eq(3)
        expect(post.settings.map(&:id_for_select)).to match_array([setting, duplicate_setting, Setting.find_by(name: 'newsetting')].map(&:id))
        expect(post.content_warnings.map(&:id_for_select)).to match_array([warning, duplicate_warning, new_warning].map(&:id))
        expect(post.labels.map(&:id_for_select)).to match_array([label, duplicate_label, Label.find_by(name: 'newlabel')].map(&:id))

        expect(Setting.count).to eq(4)
        expect(ContentWarning.count).to eq(4)
        expect(Label.count).to eq(4)
        expect(PostTag.count).to eq(9)
        expect(PostTag.where(post: post, tag: regular_tags).count).to eq(3)
        expect(PostTag.where(post: post, tag: duplicate_tags).count).to eq(3)
        expect(PostTag.where(post: post, tag: removed_tags).count).to eq(0)
      end

      it "uses extant tags if available" do
        regular_tags
        put :update, params: {
          id: user_post.id,
          post: { setting_ids: ['_setting'], content_warning_ids: ['_warning'], label_ids: ['_label'] },
        }
        expect(response).to redirect_to(post_url(user_post))
        post = assigns(:post)
        expect(post.settings).to eq([setting])
        expect(post.content_warnings).to eq([warning])
        expect(post.labels).to eq([label])
      end

      it "orders tags" do
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
          id: user_post.id,
          post: {
            setting_ids: [setting1, setting2, setting3].map(&:id),
            content_warning_ids: [warning1, warning2, warning3].map(&:id),
            label_ids: [tag1, tag2, tag3].map(&:id),
          },
        }
        expect(response).to redirect_to(post_url(user_post))
        post = assigns(:post)
        expect(post.settings).to eq([setting1, setting2, setting3])
        expect(post.content_warnings).to eq([warning1, warning2, warning3])
        expect(post.labels).to eq([tag1, tag2, tag3])
      end
    end

    context "with author changes" do
      it "correctly updates when adding new authors" do
        user_post

        Timecop.freeze(5.minutes.from_now) do
          expect {
            put :update, params: {
              id: user_post.id,
              post: {
                unjoined_author_ids: [coauthor.id],
              },
            }
          }.to change { Post::Author.count }.by(1)
        end

        expect(response).to redirect_to(post_url(user_post))
        user_post.reload
        expect(user_post.tagging_authors).to match_array([user, coauthor])

        # doesn't change joined time or invited status when inviting main user
        main_author = user_post.author_for(user)
        expect(main_author.can_owe).to eq(true)
        expect(main_author.joined).to eq(true)
        expect(main_author.joined_at).to be_the_same_time_as(user_post.created_at)

        # doesn't set joined time but does set invited status when inviting new user
        new_author = user_post.author_for(coauthor)
        expect(new_author.can_owe).to eq(true)
        expect(new_author.joined).to eq(false)
        expect(new_author.joined_at).to be_nil
      end

      it "correctly updates when removing authors" do
        post, reply = Timecop.freeze(5.minutes.ago) do
          post = create(:post, user: user, unjoined_authors: [joined_user, invited_user])
          reply = create(:reply, user: joined_user, post: post)
          [post, reply]
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
        expect(flash[:success]).to eq("Post updated.")

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
        board = create(:board, creator: user, writers: [coauthor])
        post = create(:post, user: user, board: board)

        put :update, params: {
          id: post.id,
          post: {
            unjoined_author_ids: [coauthor.id, invited_user.id],
          },
        }

        post.reload
        board.reload
        expect(post.tagging_authors).to match_array([user, coauthor, invited_user])
        expect(board.cameos).to match_array([invited_user])
      end

      it "does not add to cameos of open boards" do
        put :update, params: {
          id: user_post.id,
          post: {
            unjoined_author_ids: [coauthor.id],
          },
        }
        user_post.reload
        board.reload
        expect(user_post.tagging_authors).to match_array([user, coauthor])
        expect(board.cameos).to be_empty
      end
    end

    it "requires valid update" do
      post = create(:post,
        user: user,
        settings: [setting, removed_setting],
        content_warnings: [warning, removed_warning],
        labels: [label, removed_label],
      )

      duplicate_tags
      templated_character
      templateless_character

      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)

      expect(controller).to receive(:editor_setup).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      # for each type: keep one, remove one, create one, existing one
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
      expect(flash[:error][:message]).to eq("Post could not be updated because of the following problems:")
      expect(post.reload.subject).not_to be_empty

      # editor_setup:
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(controller.gon.editor_user[:username]).to eq(user.username)
      expect(assigns(:author_ids)).to match_array([coauthor.id])

      # templates
      templates = assigns(:templates)
      expect(templates.length).to eq(2)
      expect(templates[0]).to eq(templated_character.template)
      expect(templates[1].name).to eq('Templateless')
      expect(templates[1].plucked_characters).to eq([[templateless_character.id, templateless_character.name]])

      # tags change only in memory when save fails
      post = assigns(:post)
      expect(post.settings.size).to eq(3)
      expect(post.content_warnings.size).to eq(3)
      expect(post.labels.size).to eq(3)
      expect(post.settings.map(&:id_for_select)).to match_array(settings_select)
      expect(post.content_warnings.map(&:id_for_select)).to match_array(warnings_select)
      expect(post.labels.map(&:id_for_select)).to match_array(labels_select)
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(PostTag.count).to eq(6)
      expect(PostTag.where(post: post, tag: regular_tags).count).to eq(3)
      expect(PostTag.where(post: post, tag: duplicate_tags).count).to eq(0)
      expect(PostTag.where(post: post, tag: removed_tags).count).to eq(3)
    end

    it "works" do
      post = create(:post, user: user, unjoined_authors: [invited_user])
      create(:reply, user: joined_user, post: post)

      newcontent = post.content + 'new'
      newsubj = post.subject + 'new'
      section = create(:board_section, board: board)

      post.reload
      expect(post.tagging_authors).to match_array([user, invited_user, joined_user])
      expect(post.joined_authors).to match_array([user, joined_user])
      expect(post.viewers).to be_empty

      put :update, params: {
        id: post.id,
        post: {
          content: newcontent,
          subject: newsubj,
          description: 'desc',
          board_id: board.id,
          section_id: section.id,
          character_id: templateless_character.id,
          character_alias_id: character_alias.id,
          icon_id: icon.id,
          privacy: :access_list,
          viewer_ids: [viewer.id],
          setting_ids: [setting.id],
          content_warning_ids: [warning.id],
          label_ids: [label.id],
          unjoined_author_ids: [coauthor.id],
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post updated.")

      post.reload
      expect(post.content).to eq(newcontent)
      expect(post.subject).to eq(newsubj)
      expect(post.description).to eq('desc')
      expect(post.board_id).to eq(board.id)
      expect(post.section_id).to eq(section.id)
      expect(post.character_id).to eq(templateless_character.id)
      expect(post.character_alias_id).to eq(character_alias.id)
      expect(post.icon_id).to eq(icon.id)
      expect(post).to be_privacy_access_list
      expect(post.viewers).to match_array([viewer])
      expect(post.settings).to eq([setting])
      expect(post.content_warnings).to eq([warning])
      expect(post.labels).to eq([label])
      expect(post.reload).to be_visible_to(viewer)
      expect(post.reload).not_to be_visible_to(create(:user))
      expect(post.tagging_authors).to match_array([user, joined_user, coauthor])
      expect(post.joined_authors).to match_array([user, joined_user])
      expect(post.authors).to match_array([user, coauthor, joined_user])
    end

    it "creates NPCs" do
      post = create(:post, user: user, character: templateless_character)

      expect {
        put :update, params: {
          id: post.id,
          post: {
            board_id: board.id,
            character_id: nil,
            icon_id: icon.id,
            setting_ids: [setting.id],
          },
          character: {
            name: 'NPC',
            npc: true,
          },
        }
      }.to change { Character.count }.by(1)
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post updated.")

      post = assigns(:post).reload
      expect(post.character_id).not_to eq(templateless_character.id)
      expect(post.icon_id).to eq(icon.id)
      expect(post.character.name).to eq('NPC')
      expect(post.character).to be_npc
      expect(post.character.default_icon_id).to eq(icon.id)
      expect(post.character.nickname).to eq(post.subject)
      expect(post.character.settings).to eq([setting])
    end

    it "does not allow coauthors to edit post text" do
      skip "Is not currently implemented on saving data"
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

    it "regenerates visible_posts" do
      old_viewer = create(:user)
      new_viewer = create(:user)
      still_viewer = create(:user)
      old_circle_viewers = User.where(id: create_list(:user, 3).map(&:id))
      new_circle_viewers = User.where(id: create_list(:user, 3).map(&:id))
      shared_circle_viewers = User.where(id: create_list(:user, 2).map(&:id))
      retained_circle_viewers = User.where(id: create_list(:user, 3).map(&:id))
      unrelated = create(:user)

      all = [
        user.id,
        coauthor.id,
        old_viewer.id,
        new_viewer.id,
        still_viewer.id,
        old_circle_viewers.ids,
        new_circle_viewers.ids,
        shared_circle_viewers.ids,
        retained_circle_viewers.ids,
        unrelated.id,
      ].flatten

      all = User.where(id: all)
      circle1 = create(:access_circle, users: old_circle_viewers + shared_circle_viewers)
      circle2 = create(:access_circle, users: new_circle_viewers + shared_circle_viewers)
      circle3 = create(:access_circle, users: retained_circle_viewers)
      post = create(:post,
        user: user,
        authors: [coauthor],
        authors_locked: true,
        privacy: :access_list,
        viewers: [coauthor, old_viewer, still_viewer],
        access_circles: [circle1, circle3],
      )
      create(:reply, post: post, user: coauthor)

      all.each(&:visible_posts)
      all.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to eq(true) }

      login_as(user)

      put :update, params: {
        id: post.id,
        post: {
          viewer_ids: [coauthor.id, new_viewer.id, still_viewer.id],
          access_circle_ids: [circle2.id, circle3.id],
        },
      }

      expect(flash[:success]).to eq('Post updated.')
      post.reload
      expect(post.viewers).to match_array([new_viewer, still_viewer, coauthor])
      expect(post.access_circles).to match_array([circle2, circle3])

      old_circle_viewers.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(false) }
      new_circle_viewers.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(false) }
      shared_circle_viewers.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(false) }
      retained_circle_viewers.each { |u| expect(Rails.cache.exist?(PostViewer.cache_string_for(u.id))).to be(true) }
      expect(Rails.cache.exist?(PostViewer.cache_string_for(coauthor.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(old_viewer.id))).to be(false)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(new_viewer.id))).to be(false)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(still_viewer.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(unrelated.id))).to be(true)
      expect(Rails.cache.exist?(PostViewer.cache_string_for(user.id))).to be(true)
    end
  end

  context "metadata" do
    it "allows coauthors" do
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
      expect(flash[:success]).to eq("Post updated.")
      post.reload
      expect(post.subject).to eq("new subject")
    end

    it "allows invited coauthors before they reply" do
      login_as(coauthor)
      post = create(:post, user: user, authors: [user, coauthor], authors_locked: true, subject: "test subject")
      put :update, params: {
        id: post.id,
        post: {
          subject: "new subject",
        },
      }
      expect(response).to redirect_to(post_url(post))
      expect(flash[:success]).to eq("Post updated.")
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
      login_as(post.user)
      put :update, params: {
        id: post.id,
        post: {
          private_note: 'look a note!',
        },
      }
      expect(Post.find_by(id: post.id).author_for(post.user).private_note).not_to be_nil
    end

    it "updates with other changes" do
      post = create(:post, content: 'old')
      login_as(post.user)
      put :update, params: {
        id: post.id,
        post: {
          private_note: 'look a note!',
          content: 'new',
        },
      }
      expect(Post.find_by(id: post.id).author_for(post.user).private_note).not_to be_nil
      expect(post.reload.content).to eq('new')
    end

    it "updates with coauthor" do
      login_as(reply.user)
      put :update, params: {
        id: post.id,
        post: {
          private_note: 'look a note!',
        },
      }
      expect(Post.find_by(id: post.id).author_for(reply.user).private_note).not_to be_nil
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
