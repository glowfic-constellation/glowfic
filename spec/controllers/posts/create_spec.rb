RSpec.describe PostsController, 'POST create' do
  let(:user) { create(:user) }
  let(:coauthor) { create(:user) }

  let(:board) { create(:board) }

  let(:settings) { create_list(:setting, 2) }
  let(:warnings) { create_list(:content_warning, 2) }
  let(:labels) { create_list(:label, 2) }
  let(:fonts) { create_list(:font, 2) }
  let(:setting_ids) { [settings[0].id, "_ #{settings[1].name}", '_other'] }
  let(:warning_ids) { [warnings[0].id, "_#{warnings[1].name}", '_other'] }
  let(:label_ids) { [labels[0].id, "_#{labels[1].name}", '_other'] }
  let(:font_ids) { fonts.map(&:id) }

  let(:templateless_character) { create(:character, user: user) }
  let(:templated_character) { create(:template_character, user: user) }
  let(:character_alias) { create(:alias, character: templateless_character) }
  let(:icon) { create(:icon, user: user) }

  it "requires login" do
    post :create
    expect(response).to redirect_to(root_url)
    expect(flash[:error]).to eq("You must be logged in to view that page.")
  end

  it "requires full account" do
    login_as(create(:reader_user))
    post :create
    expect(response).to redirect_to(posts_path)
    expect(flash[:error]).to eq("You do not have permission to create posts.")
  end

  context "scrape" do
    let(:user) { create(:importing_user) }
    let(:url) { 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat' }

    before(:each) { clear_enqueued_jobs }

    include ActiveJob::TestHelper

    it "requires valid user" do
      user = create(:user)
      login_as(user)
      post :create, params: { button_import: true }
      expect(response).to redirect_to(new_post_path)
      expect(flash[:error]).to eq("You do not have access to this feature.")
    end

    context "with importer" do
      before(:each) { login_as(user) }

      it "requires valid dreamwidth url" do
        post :create, params: { button_import: true, dreamwidth_url: 'http://www.google.com' }
        expect(response).to render_template(:new)
        expect(flash[:error]).to eq("Invalid URL provided.")
      end

      it "requires extant usernames" do
        stub_fixture(url, 'scrape_no_replies')
        post :create, params: { button_import: true, dreamwidth_url: url }
        expect(response).to render_template(:new)
        expect(flash[:error][:message]).to start_with("The following usernames were not recognized")
        expect(flash[:error][:array]).to include("wild_pegasus_appeared")
        expect(ScrapePostJob).not_to have_been_enqueued
      end

      it "queues job" do
        create(:character, user: user, screenname: 'wild-pegasus-appeared')
        stub_fixture(url, 'scrape_no_replies')
        post :create, params: { button_import: true, dreamwidth_url: url }
        expect(response).to redirect_to(posts_url)
        expect(flash[:success]).to eq("Post has begun importing. You will be updated on progress via site message.")
        expect(ScrapePostJob).to have_been_enqueued.with(url, {}, user: user).on_queue('low')
      end

      it "performs scrape" do
        create(:character, user: user, screenname: 'wild-pegasus-appeared')
        board = create(:board, creator: user)
        stub_fixture(url, 'scrape_no_replies')
        allow(STDOUT).to receive(:puts).and_call_original
        allow(STDOUT).to receive(:puts).with("Importing thread 'linear b'")

        perform_enqueued_jobs do
          post :create, params: { button_import: true, dreamwidth_url: url, board_id: board.id }
        end

        expect(response).to redirect_to(posts_url)
        expect(flash[:success]).to eq("Post has begun importing. You will be updated on progress via site message.")
        expect(Message.find_by(recipient: user, sender_id: 0).subject).to eq('Post import succeeded')
        expect(Post.find_by(subject: 'linear b')).to be_present
      end
    end
  end

  context "preview" do
    before(:each) { login_as(user) }

    it "sets expected variables" do
      templated_character
      expect(controller).to receive(:editor_setup).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      post :create, params: {
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
          font_ids: font_ids,
          unjoined_author_ids: [user.id, coauthor.id],
        },
      }
      expect(response).to render_template(:preview)
      expect(assigns(:written)).to be_an_instance_of(Post)
      expect(assigns(:written)).to be_a_new_record
      expect(assigns(:written).user).to eq(user)
      expect(assigns(:written).character).to eq(templateless_character)
      expect(assigns(:written).icon).to eq(icon)
      expect(assigns(:written).character_alias).to eq(character_alias)
      expect(assigns(:post)).to eq(assigns(:written))
      expect(assigns(:page_title)).to eq('Previewing: test')
      expect(assigns(:author_ids)).to match_array([user.id, coauthor.id])

      # tags
      expect(assigns(:post).settings.size).to eq(0)
      expect(assigns(:post).content_warnings.size).to eq(0)
      expect(assigns(:post).labels.size).to eq(0)
      expect(assigns(:post).fonts.size).to eq(0)
      expect(assigns(:settings).map(&:id_for_select)).to match_array(settings.map(&:id) + ['_other'])
      expect(assigns(:content_warnings).map(&:id_for_select)).to match_array(warnings.map(&:id) + ['_other'])
      expect(assigns(:labels).map(&:id_for_select)).to match_array(labels.map(&:id) + ['_other'])
      expect(assigns(:fonts).map(&:id)).to match_array(fonts.map(&:id))
      expect(Setting.count).to eq(2)
      expect(ContentWarning.count).to eq(2)
      expect(Label.count).to eq(2)
      expect(Font.count).to eq(2)
      expect(PostTag.count).to eq(0)

      # editor_setup:
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(controller.gon.editor_user[:username]).to eq(user.username)

      # templates
      templateless_pluck = [[templateless_character.id, templateless_character.name]]
      templates = assigns(:templates)
      expect(templates.length).to eq(3)
      expect(templates[0].name).to eq('Post characters')
      expect(templates[0].plucked_characters).to eq(templateless_pluck)
      expect(templates[1]).to eq(templated_character.template)
      expect(templates[2].name).to eq('Templateless')
      expect(templates[2].plucked_characters).to eq(templateless_pluck)
    end

    it "does not crash without arguments" do
      post :create, params: { button_preview: true }
      expect(response).to render_template(:preview)
      expect(assigns(:written)).to be_an_instance_of(Post)
      expect(assigns(:written)).to be_a_new_record
      expect(assigns(:written).user).to eq(user)
    end

    it "does not create authors or viewers" do
      board = create(:board, creator: user, authors_locked: true)

      expect {
        post :create, params: {
          button_preview: true,
          post: {
            subject: 'test subject',
            privacy: :access_list,
            board_id: board.id,
            unjoined_author_ids: [coauthor.id],
            viewer_ids: [coauthor.id, create(:user).id],
            content: 'test content',
          },
        }
      }.not_to change { [Post::Author.count, PostViewer.count, BoardAuthor.count] }

      expect(flash[:error]).to be_nil
      expect(assigns(:page_title)).to eq('Previewing: ' + assigns(:post).subject.to_s)
    end
  end

  context "make changes" do
    before(:each) { login_as(user) }

    [Label, Setting, ContentWarning].each do |tag_class|
      it "creates new #{tag_class.table_name.humanize(capitalize: false)}" do
        # rubocop:disable Rails/SaveBang
        snake_class = tag_class.name.underscore
        existing_name = create(snake_class.to_sym)
        existing_case = create(snake_class.to_sym)
        tags = ['_atag', '_atag', create(snake_class.to_sym).id, '', '_' + existing_name.name, '_' + existing_case.name.upcase]
        expect {
          post :create, params: {
            post: {
              subject: 'a',
              board_id: board.id,
              snake_class.foreign_key.pluralize => tags,
            },
          }
        }.to change { tag_class.count }.by(1)
        expect(tag_class.last.name).to eq('atag')
        expect(assigns(:post).send(snake_class.pluralize.to_sym).count).to eq(4)
        # rubocop:enable Rails/SaveBang
      end
    end

    context "authors" do
      let(:time) { 5.minutes.ago }

      before(:each) { create(:user) }

      it "creates new post authors correctly" do
        Timecop.freeze(time) do
          expect {
            post :create, params: {
              post: {
                subject: 'a',
                user_id: user.id,
                board_id: board.id,
                unjoined_author_ids: [coauthor.id],
                private_note: 'there is a note!',
              },
            }
          }.to change { Post::Author.count }.by(2)
        end

        post = assigns(:post).reload
        expect(post.tagging_authors).to match_array([user, coauthor])

        post_author = post.author_for(user)
        expect(post_author.can_owe).to eq(true)
        expect(post_author.joined).to eq(true)
        expect(post_author.joined_at).to be_the_same_time_as(time)
        expect(post_author.private_note).to eq('there is a note!')

        other_post_author = post.author_for(coauthor)
        expect(other_post_author.can_owe).to eq(true)
        expect(other_post_author.joined).to eq(false)
        expect(other_post_author.joined_at).to be_nil
      end

      it "handles post submitted with no authors" do
        Timecop.freeze(time) do
          expect {
            post :create, params: {
              post: {
                subject: 'a',
                user_id: user.id,
                board_id: board.id,
                unjoined_author_ids: [''],
              },
            }
          }.to change { Post::Author.count }.by(1)
        end

        post = assigns(:post).reload
        expect(post.tagging_authors).to eq([post.user])
        expect(post.authors).to match_array([user])

        post_author = post.post_authors.first
        expect(post_author.can_owe).to eq(true)
        expect(post_author.joined).to eq(true)
        expect(post_author.joined_at).to be_the_same_time_as(time)
      end

      it "adds new post authors to board cameo" do
        third_user = create(:user)
        board = create(:board, creator: user, writers: [coauthor])

        expect {
          post :create, params: {
            post: {
              subject: 'a',
              user_id: user.id,
              board_id: board.id,
              unjoined_author_ids: [user.id, coauthor.id, third_user.id],
            },
          }
        }.to change { BoardAuthor.count }.by(1)

        post = assigns(:post).reload
        expect(post.tagging_authors).to match_array([user, coauthor, third_user])

        board.reload
        expect(board.writers).to match_array([user, coauthor])
        expect(board.cameos).to match_array([third_user])
      end

      it "does not add to cameos of open boards" do
        expect(board.cameos).to be_empty

        expect {
          post :create, params: {
            post: {
              subject: 'a',
              user_id: user.id,
              board_id: board.id,
              unjoined_author_ids: [user.id, coauthor.id],
            },
          }
        }.not_to change { BoardAuthor.count }

        post = assigns(:post).reload
        expect(post.tagging_authors).to match_array([user, coauthor])

        board.reload
        expect(board.writers).to eq([board.creator])
        expect(board.cameos).to be_empty
      end

      it "handles new post authors already being in cameos" do
        board = create(:board, creator: user, cameos: [coauthor])

        post :create, params: {
          post: {
            subject: 'a',
            user_id: user.id,
            board_id: board.id,
            unjoined_author_ids: [user.id, coauthor.id],
          },
        }

        expect(flash[:success]).to eq("Post created.")
        post = assigns(:post).reload
        expect(post.tagging_authors).to match_array([user, coauthor])

        board.reload
        expect(board.creator).to eq(user)
        expect(board.cameos).to match_array([coauthor])
      end
    end

    it "handles invalid posts" do
      templated_character
      expect(controller).to receive(:editor_setup).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original

      # valid post requires a board_id
      post :create, params: {
        post: {
          subject: 'asubjct',
          content: 'acontnt',
          setting_ids: setting_ids,
          content_warning_ids: warning_ids,
          label_ids: label_ids,
          font_ids: font_ids,
          character_id: templateless_character.id,
          unjoined_author_ids: [user.id, coauthor.id],
        },
      }

      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to eq("Post could not be created because of the following problems:")
      expect(assigns(:post)).not_to be_persisted
      expect(assigns(:post).user).to eq(user)
      expect(assigns(:post).subject).to eq('asubjct')
      expect(assigns(:post).content).to eq('acontnt')
      expect(assigns(:page_title)).to eq('New Post')
      expect(assigns(:author_ids)).to match_array([user.id, coauthor.id])

      # editor_setup:
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(controller.gon.editor_user[:username]).to eq(user.username)

      # templates
      templateless_pluck = [[templateless_character.id, templateless_character.name]]
      templates = assigns(:templates)
      expect(templates.length).to eq(3)
      expect(templates[0].name).to eq('Post characters')
      expect(templates[0].plucked_characters).to eq(templateless_pluck)
      expect(templates[1]).to eq(templated_character.template)
      expect(templates[2].name).to eq('Templateless')
      expect(templates[2].plucked_characters).to eq(templateless_pluck)

      # tags
      post = assigns(:post)
      expect(post.settings.size).to eq(3)
      expect(post.content_warnings.size).to eq(3)
      expect(post.labels.size).to eq(3)
      expect(post.fonts.size).to eq(2)
      expect(post.settings.map(&:id_for_select)).to match_array(settings.map(&:id) + ['_other'])
      expect(post.content_warnings.map(&:id_for_select)).to match_array(warnings.map(&:id) + ['_other'])
      expect(post.labels.map(&:id_for_select)).to match_array(labels.map(&:id) + ['_other'])
      expect(post.fonts.map(&:id)).to match_array(fonts.map(&:id))
      expect(Setting.count).to eq(2)
      expect(ContentWarning.count).to eq(2)
      expect(Label.count).to eq(2)
      expect(Font.count).to eq(2)
      expect(PostTag.count).to eq(0)
    end

    it "creates a post" do
      viewer = create(:user)
      section = create(:board_section, board: board)

      expect {
        post :create, params: {
          post: {
            subject: 'asubjct',
            content: 'acontnt',
            description: 'adesc',
            board_id: board.id,
            section_id: section.id,
            character_id: templateless_character.id,
            icon_id: icon.id,
            character_alias_id: character_alias.id,
            privacy: :access_list,
            viewer_ids: [viewer.id],
            setting_ids: setting_ids,
            content_warning_ids: warning_ids,
            label_ids: label_ids,
            font_ids: font_ids,
            unjoined_author_ids: [coauthor.id],
          },
        }
      }.to change { Post.count }.by(1)
      expect(response).to redirect_to(post_path(assigns(:post)))
      expect(flash[:success]).to eq("Post created.")

      post = assigns(:post).reload
      expect(post).to be_persisted
      expect(post.user).to eq(user)
      expect(post.last_user).to eq(user)
      expect(post.subject).to eq('asubjct')
      expect(post.content).to eq('acontnt')
      expect(post.description).to eq('adesc')
      expect(post.board).to eq(board)
      expect(post.section).to eq(section)
      expect(post.character_id).to eq(templateless_character.id)
      expect(post.icon_id).to eq(icon.id)
      expect(post.character_alias_id).to eq(character_alias.id)
      expect(post).to be_privacy_access_list
      expect(post.viewers).to match_array([viewer])
      expect(post.reload).to be_visible_to(viewer)
      expect(post.reload).not_to be_visible_to(create(:user))

      expect(post.authors).to match_array([user, coauthor])
      expect(post.tagging_authors).to match_array([user, coauthor])
      expect(post.unjoined_authors).to match_array([coauthor])
      expect(post.joined_authors).to match_array([user])

      # tags
      expect(post.settings.size).to eq(3)
      expect(post.content_warnings.size).to eq(3)
      expect(post.labels.size).to eq(3)
      expect(post.fonts.size).to eq(2)
      expect(post.settings.map(&:id_for_select)).to match_array(settings.map(&:id) + [Setting.last.id])
      expect(post.content_warnings.map(&:id_for_select)).to match_array(warnings.map(&:id) + [ContentWarning.last.id])
      expect(post.labels.map(&:id_for_select)).to match_array(labels.map(&:id) + [Label.last.id])
      expect(post.fonts.map(&:id)).to match_array(fonts.map(&:id))
      expect(Setting.count).to eq(3)
      expect(ContentWarning.count).to eq(3)
      expect(Label.count).to eq(3)
      expect(Font.count).to eq(2)
      expect(PostTag.count).to eq(9)
    end

    it "creates NPCs" do
      expect {
        post :create, params: {
          post: {
            subject: 'asubjct',
            board_id: board.id,
            character_id: nil,
            icon_id: icon.id,
            setting_ids: setting_ids,
          },
          character: {
            name: 'NPC',
            npc: true,
          },
        }
      }.to change { Post.count }.by(1).and change { Character.count }.by(1)
      expect(response).to redirect_to(post_path(assigns(:post)))
      expect(flash[:success]).to eq("Post created.")

      post = assigns(:post).reload
      expect(post).to be_persisted
      expect(post.character_id).not_to eq(templateless_character.id)
      expect(post.icon_id).to eq(icon.id)
      expect(post.character.name).to eq('NPC')
      expect(post.character).to be_npc
      expect(post.character.default_icon_id).to eq(icon.id)
      expect(post.character.nickname).to eq('asubjct') # post disambiguator
      expect(post.character.settings.map(&:id_for_select)).to match_array(settings.map(&:id) + [Setting.last.id])
    end

    it "generates a flat post" do
      post :create, params: {
        post: {
          subject: 'subject',
          board_id: board.id,
          privacy: :registered,
          content: 'content',
        },
      }
      post = assigns(:post)
      expect(post.flat_post).not_to be_nil
    end
  end

  context "with blocks" do
    let(:user) { create(:user) }
    let(:blocked) { create(:user) }
    let(:blocking) { create(:user) }
    let(:other_user) { create(:user) }
    let(:blocking_key) { Block.cache_string_for(blocking.id, 'hidden') }
    let(:blocker_key) { Block.cache_string_for(blocked.id, 'blocked') }

    before(:each) do
      create(:block, blocking_user: user, blocked_user: blocked, hide_me: :posts)
      create(:block, blocking_user: blocking, blocked_user: user, hide_them: :posts)
      # make sure the caches are generated for both
      blocking.hidden_posts
      blocked.blocked_posts
    end

    it "regenerates blocked and hidden posts for poster" do
      login_as(user)

      post :create, params: {
        post: {
          subject: "subject",
          user_id: user.id,
          board_id: board.id,
          authors_locked: true,
          unjoined_author_ids: [other_user.id],
        },
      }

      expect(Rails.cache.exist?(blocking_key)).to be(false)
      expect(Rails.cache.exist?(blocker_key)).to be(false)

      post = assigns(:post)
      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])
    end

    it "regenerates blocked and hidden posts for coauthor" do
      login_as(other_user)

      post :create, params: {
        post: {
          subject: "subject",
          user_id: other_user.id,
          board_id: board.id,
          authors_locked: true,
          unjoined_author_ids: [user.id],
        },
      }

      expect(Rails.cache.exist?(blocking_key)).to be(false)
      expect(Rails.cache.exist?(blocker_key)).to be(false)

      post = assigns(:post)
      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])
    end
  end
end
