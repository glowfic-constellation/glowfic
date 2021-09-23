RSpec.describe PostsController, 'POST create' do
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
    include ActiveJob::TestHelper
    it "requires valid user" do
      user = create(:user)
      login_as(user)
      post :create, params: { button_import: true }
      expect(response).to redirect_to(new_post_path)
      expect(flash[:error]).to eq("You do not have access to this feature.")
    end

    it "requires valid dreamwidth url" do
      user = create(:importing_user)
      login_as(user)
      post :create, params: { button_import: true, dreamwidth_url: 'http://www.google.com' }
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq("Invalid URL provided.")
    end

    it "requires extant usernames" do
      clear_enqueued_jobs
      user = create(:importing_user)
      login_as(user)
      url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
      stub_fixture(url, 'scrape_no_replies')
      post :create, params: { button_import: true, dreamwidth_url: url }
      expect(response).to render_template(:new)
      expect(flash[:error][:message]).to start_with("The following usernames were not recognized")
      expect(flash[:error][:array]).to include("wild_pegasus_appeared")
      expect(ScrapePostJob).not_to have_been_enqueued
    end

    it "scrapes" do
      clear_enqueued_jobs
      user = create(:importing_user)
      login_as(user)
      create(:character, user: user, screenname: 'wild-pegasus-appeared')
      url = 'http://wild-pegasus-appeared.dreamwidth.org/403.html?style=site&view=flat'
      stub_fixture(url, 'scrape_no_replies')
      post :create, params: { button_import: true, dreamwidth_url: url }
      expect(response).to redirect_to(posts_url)
      expect(flash[:success]).to eq("Post has begun importing. You will be updated on progress via site message.")
      expect(ScrapePostJob).to have_been_enqueued.with(url, nil, nil, nil, nil, user.id).on_queue('low')
    end
  end

  context "preview" do
    it "sets expected variables" do
      user = create(:user)
      login_as(user)
      setting1 = create(:setting)
      setting2 = create(:setting)
      warning1 = create(:content_warning)
      warning2 = create(:content_warning)
      label1 = create(:label)
      label2 = create(:label)
      char1 = create(:character, user: user)
      char2 = create(:template_character, user: user)
      icon = create(:icon)
      calias = create(:alias, character: char1)
      coauthor = create(:user)
      expect(controller).to receive(:editor_setup).and_call_original
      expect(controller).to receive(:setup_layout_gon).and_call_original
      post :create, params: {
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
          unjoined_author_ids: [user.id, coauthor.id],
        },
      }
      expect(response).to render_template(:preview)
      expect(assigns(:written)).to be_an_instance_of(Post)
      expect(assigns(:written)).to be_a_new_record
      expect(assigns(:written).user).to eq(user)
      expect(assigns(:written).character).to eq(char1)
      expect(assigns(:written).icon).to eq(icon)
      expect(assigns(:written).character_alias).to eq(calias)
      expect(assigns(:post)).to eq(assigns(:written))
      expect(assigns(:page_title)).to eq('Previewing: test')
      expect(assigns(:author_ids)).to match_array([user.id, coauthor.id])

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

      # editor_setup:
      expect(assigns(:javascripts)).to include('posts/editor')
      expect(controller.gon.editor_user[:username]).to eq(user.username)

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
    end

    it "does not crash without arguments" do
      user = create(:user)
      login_as(user)
      post :create, params: { button_preview: true }
      expect(response).to render_template(:preview)
      expect(assigns(:written)).to be_an_instance_of(Post)
      expect(assigns(:written)).to be_a_new_record
      expect(assigns(:written).user).to eq(user)
    end

    it "does not create authors or viewers" do
      user = create(:user)
      login_as(user)

      coauthor = create(:user)
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
      }.not_to change { [Post::Author.count, PostViewer.count, Continuity::Author.count] }

      expect(flash[:error]).to be_nil
      expect(assigns(:page_title)).to eq('Previewing: ' + assigns(:post).subject.to_s)
    end
  end

  it "creates new labels" do
    existing_name = create(:label)
    existing_case = create(:label)
    tags = ['_atag', '_atag', create(:label).id, '', '_' + existing_name.name, '_' + existing_case.name.upcase]
    login
    expect {
      post :create, params: { post: { subject: 'a', board_id: create(:board).id, label_ids: tags } }
    }.to change { Label.count }.by(1)
    expect(Label.last.name).to eq('atag')
    expect(assigns(:post).labels.count).to eq(4)
  end

  it "creates new settings" do
    existing_name = create(:setting)
    existing_case = create(:setting)
    tags = [
      '_atag',
      '_atag',
      create(:setting).id,
      '',
      '_' + existing_name.name,
      '_' + existing_case.name.upcase,
    ]
    login
    expect {
      post :create, params: { post: { subject: 'a', board_id: create(:board).id, setting_ids: tags } }
    }.to change { Setting.count }.by(1)
    expect(Setting.last.name).to eq('atag')
    expect(assigns(:post).settings.count).to eq(4)
  end

  it "creates new content warnings" do
    existing_name = create(:content_warning)
    existing_case = create(:content_warning)
    tags = [
      '_atag',
      '_atag',
      create(:content_warning).id,
      '',
      '_' + existing_name.name,
      '_' + existing_case.name.upcase,
    ]
    login
    expect {
      post :create, params: {
        post: { subject: 'a', board_id: create(:board).id, content_warning_ids: tags },
      }
    }.to change { ContentWarning.count }.by(1)
    expect(ContentWarning.last.name).to eq('atag')
    expect(assigns(:post).content_warnings.count).to eq(4)
  end

  it "creates new post authors correctly" do
    user = create(:user)
    other_user = create(:user)
    create(:user) # user should not be author
    board_creator = create(:user) # user should not be author
    board = create(:board, creator: board_creator)
    login_as(user)

    time = 5.minutes.ago
    Timecop.freeze(time) do
      expect {
        post :create, params: {
          post: {
            subject: 'a',
            user_id: user.id,
            board_id: board.id,
            unjoined_author_ids: [other_user.id],
            private_note: 'there is a note!',
          },
        }
      }.to change { Post::Author.count }.by(2)
    end

    post = assigns(:post).reload
    expect(post.tagging_authors).to match_array([user, other_user])

    post_author = post.author_for(user)
    expect(post_author.can_owe).to eq(true)
    expect(post_author.joined).to eq(true)
    expect(post_author.joined_at).to be_the_same_time_as(time)
    expect(post_author.private_note).to eq('there is a note!')

    other_post_author = post.author_for(other_user)
    expect(other_post_author.can_owe).to eq(true)
    expect(other_post_author.joined).to eq(false)
    expect(other_post_author.joined_at).to be_nil
  end

  it "handles post submitted with no authors" do
    user = create(:user)
    create(:user) # non-author
    board_creator = create(:user)
    board = create(:board, creator: board_creator)
    login_as(user)

    time = 5.minutes.ago
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
    user = create(:user)
    other_user = create(:user)
    third_user = create(:user)
    create(:user) # separate user
    board = create(:board, creator: user, writers: [other_user])

    login_as(user)
    expect {
      post :create, params: {
        post: {
          subject: 'a',
          user_id: user.id,
          board_id: board.id,
          unjoined_author_ids: [user.id, other_user.id, third_user.id],
        },
      }
    }.to change { Continuity::Author.count }.by(1)

    post = assigns(:post).reload
    expect(post.tagging_authors).to match_array([user, other_user, third_user])

    board.reload
    expect(board.writers).to match_array([user, other_user])
    expect(board.cameos).to match_array([third_user])
  end

  it "does not add to cameos of open boards" do
    user = create(:user)
    other_user = create(:user)
    board = create(:board)
    expect(board.cameos).to be_empty

    login_as(user)
    expect {
      post :create, params: {
        post: {
          subject: 'a',
          user_id: user.id,
          board_id: board.id,
          unjoined_author_ids: [user.id, other_user.id],
        },
      }
    }.not_to change { Continuity::Author.count }

    post = assigns(:post).reload
    expect(post.tagging_authors).to match_array([user, other_user])

    board.reload
    expect(board.writers).to eq([board.creator])
    expect(board.cameos).to be_empty
  end

  it "handles new post authors already being in cameos" do
    user = create(:user)
    other_user = create(:user)
    board = create(:board, creator: user, cameos: [other_user])

    login_as(user)
    post :create, params: {
      post: {
        subject: 'a',
        user_id: user.id,
        board_id: board.id,
        unjoined_author_ids: [user.id, other_user.id],
      },
    }

    expect(flash[:success]).to eq("You have successfully posted.")
    post = assigns(:post).reload
    expect(post.tagging_authors).to match_array([user, other_user])

    board.reload
    expect(board.creator).to eq(user)
    expect(board.cameos).to match_array([other_user])
  end

  it "handles invalid posts" do
    user = create(:user)
    login_as(user)
    setting1 = create(:setting)
    setting2 = create(:setting)
    warning1 = create(:content_warning)
    warning2 = create(:content_warning)
    label1 = create(:label)
    label2 = create(:label)
    char1 = create(:character, user: user)
    char2 = create(:template_character, user: user)
    coauthor = create(:user)
    expect(controller).to receive(:editor_setup).and_call_original
    expect(controller).to receive(:setup_layout_gon).and_call_original

    # valid post requires a board_id
    post :create, params: {
      post: {
        subject: 'asubjct',
        content: 'acontnt',
        setting_ids: [setting1.id, "_ #{setting2.name}", '_other'],
        content_warning_ids: [warning1.id, "_#{warning2.name}", '_other'],
        label_ids: [label1.id, "_#{label2.name}", '_other'],
        character_id: char1.id,
        unjoined_author_ids: [user.id, coauthor.id],
      },
    }

    expect(response).to render_template(:new)
    expect(flash[:error][:message]).to eq("Your post could not be saved because of the following problems:")
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
    expect(assigns(:post).settings.size).to eq(3)
    expect(assigns(:post).content_warnings.size).to eq(3)
    expect(assigns(:post).labels.size).to eq(3)
    expect(assigns(:post).settings.map(&:id_for_select)).to match_array([setting1.id, setting2.id, '_other'])
    expect(assigns(:post).content_warnings.map(&:id_for_select)).to match_array([warning1.id, warning2.id, '_other'])
    expect(assigns(:post).labels.map(&:id_for_select)).to match_array([label1.id, label2.id, '_other'])
    expect(Setting.count).to eq(2)
    expect(ContentWarning.count).to eq(2)
    expect(Label.count).to eq(2)
    expect(PostTag.count).to eq(0)
  end

  it "creates a post" do
    user = create(:user)
    login_as(user)
    board = create(:board)
    section = create(:board_section, board: board)
    char = create(:character, user: user)
    icon = create(:icon, user: user)
    calias = create(:alias, character: char)
    viewer = create(:user)
    setting1 = create(:setting)
    setting2 = create(:setting)
    warning1 = create(:content_warning)
    warning2 = create(:content_warning)
    label1 = create(:label)
    label2 = create(:label)
    coauthor = create(:user)

    expect {
      post :create, params: {
        post: {
          subject: 'asubjct',
          content: 'acontnt',
          description: 'adesc',
          board_id: board.id,
          section_id: section.id,
          character_id: char.id,
          icon_id: icon.id,
          character_alias_id: calias.id,
          privacy: :access_list,
          viewer_ids: [viewer.id],
          setting_ids: [setting1.id, "_ #{setting2.name}", '_other'],
          content_warning_ids: [warning1.id, "_#{warning2.name}", '_other'],
          label_ids: [label1.id, "_#{label2.name}", '_other'],
          unjoined_author_ids: [coauthor.id],
        },
      }
    }.to change { Post.count }.by(1)
    expect(response).to redirect_to(post_path(assigns(:post)))
    expect(flash[:success]).to eq("You have successfully posted.")

    post = assigns(:post).reload
    expect(post).to be_persisted
    expect(post.user).to eq(user)
    expect(post.last_user).to eq(user)
    expect(post.subject).to eq('asubjct')
    expect(post.content).to eq('acontnt')
    expect(post.description).to eq('adesc')
    expect(post.board).to eq(board)
    expect(post.section).to eq(section)
    expect(post.character_id).to eq(char.id)
    expect(post.icon_id).to eq(icon.id)
    expect(post.character_alias_id).to eq(calias.id)
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
    expect(post.settings.map(&:id_for_select)).to match_array([setting1.id, setting2.id, Setting.last.id])
    expect(post.content_warnings.map(&:id_for_select)).to match_array([warning1.id, warning2.id, ContentWarning.last.id])
    expect(post.labels.map(&:id_for_select)).to match_array([label1.id, label2.id, Label.last.id])
    expect(Setting.count).to eq(3)
    expect(ContentWarning.count).to eq(3)
    expect(Label.count).to eq(3)
    expect(PostTag.count).to eq(9)
  end

  it "generates a flat post" do
    user = create(:user)
    login_as(user)
    post :create, params: {
      post: {
        subject: 'subject',
        board_id: create(:board).id,
        privacy: :registered,
        content: 'content',
      },
    }
    post = assigns(:post)
    expect(post.flat_post).not_to be_nil
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
      expect(blocking.hidden_posts).to be_empty
      expect(blocked.blocked_posts).to be_empty

      login_as(user)

      post :create, params: {
        post: {
          subject: "subject",
          user_id: user.id,
          board_id: create(:board).id,
          authors_locked: true,
          unjoined_author_ids: [other_user.id],
        },
      }

      expect(Rails.cache.exist?(Block.cache_string_for(blocking.id, 'hidden'))).to be(false)
      expect(Rails.cache.exist?(Block.cache_string_for(blocked.id, 'blocked'))).to be(false)

      post = assigns(:post)
      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])
    end

    it "regenerates blocked and hidden posts for coauthor" do
      expect(blocking.hidden_posts).to be_empty
      expect(blocked.blocked_posts).to be_empty

      login_as(other_user)

      post :create, params: {
        post: {
          subject: "subject",
          user_id: other_user.id,
          board_id: create(:board).id,
          authors_locked: true,
          unjoined_author_ids: [user.id],
        },
      }

      expect(Rails.cache.exist?(Block.cache_string_for(blocking.id, 'hidden'))).to be(false)
      expect(Rails.cache.exist?(Block.cache_string_for(blocked.id, 'blocked'))).to be(false)

      post = assigns(:post)
      expect(blocking.hidden_posts).to eq([post.id])
      expect(blocked.blocked_posts).to eq([post.id])
    end
  end
end
