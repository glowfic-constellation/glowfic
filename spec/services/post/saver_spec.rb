require "spec_helper"

RSpec.shared_examples "post" do |method|
  let(:user) { create(:user) }
  let(:post) {
    if method == 'update!'
      create(:post, user: user, board: create(:board))
    else
      build(:post, user: user, board: create(:board))
    end
  }
  let(:params) { ActionController::Parameters.new({ id: post.id }) }

  it "creates new labels" do
    existing_name = create(:label)
    existing_case = create(:label)
    tags = ['_atag', '_atag', create(:label).id, '', '_' + existing_name.name, '_' + existing_case.name.upcase]

    params[:post] = { subject: 'a', board_id: create(:board).id, label_ids: tags }
    saver = Post::Saver.new(post, user: user, params: params)
    expect { saver.send(method) }.to change{Label.count}.by(1)

    expect(Label.last.name).to eq('atag')
    expect(post.reload.labels.count).to eq(4)
  end

  it "creates new settings" do
    existing_name = create(:setting)
    existing_case = create(:setting)
    tags = ['_atag', '_atag', create(:setting).id, '', '_' + existing_name.name, '_' + existing_case.name.upcase]

    params[:post] = { subject: 'a', board_id: create(:board).id, setting_ids: tags }
    saver = Post::Saver.new(post, user: user, params: params)
    expect { saver.send(method) }.to change{Setting.count}.by(1)

    expect(Setting.last.name).to eq('atag')
    expect(post.reload.settings.count).to eq(4)
  end

  it "creates new content warnings" do
    existing_name = create(:content_warning)
    existing_case = create(:content_warning)
    tags = ['_atag', '_atag', create(:content_warning).id, '', '_' + existing_name.name, '_' + existing_case.name.upcase]

    params[:post] = { subject: 'a', board_id: create(:board).id, content_warning_ids: tags }
    saver = Post::Saver.new(post, user: user, params: params)
    expect { saver.send(method) }.to change{ContentWarning.count}.by(1)

    expect(ContentWarning.last.name).to eq('atag')
    expect(post.reload.content_warnings.count).to eq(4)
  end

  it "uses extant tags if available" do
    setting_ids = ['_setting']
    setting = create(:setting, name: 'setting')
    warning_ids = ['_warning']
    warning = create(:content_warning, name: 'warning')
    label_ids = ['_label']
    tag = create(:label, name: 'label')
    params[:post] = { setting_ids: setting_ids, content_warning_ids: warning_ids, label_ids: label_ids }
    saver = Post::Saver.new(post, user: user, params: params)
    saver.send(method)

    post.reload
    expect(post.settings).to eq([setting])
    expect(post.content_warnings).to eq([warning])
    expect(post.labels).to eq([tag])
  end

  it "updates board cameos if necessary" do
    other_user = create(:user)
    third_user = create(:user)
    create(:user) # separate user
    board = create(:board, creator: user, coauthors: [other_user])

    params[:post] = {
      subject: 'a',
      user_id: user.id,
      board_id: board.id,
      unjoined_author_ids: [other_user.id, third_user.id]
    }
    saver = Post::Saver.new(post, user: user, params: params)

    expect { saver.send(method) }.to change { BoardAuthor.count }.by(1)

    post.reload
    expect(post.tagging_authors).to match_array([user, other_user, third_user])

    board.reload
    expect(board.creator).to eq(user)
    expect(board.coauthors).to match_array([other_user])
    expect(board.cameos).to match_array([third_user])
  end

  it "does not add to cameos of open boards" do
    other_user = create(:user)
    board = create(:board)
    expect(board.cameos).to be_empty

    params[:post] = {
      subject: 'a',
      user_id: user.id,
      board_id: board.id,
      unjoined_author_ids: [other_user.id]
    }
    saver = Post::Saver.new(post, user: user, params: params)

    expect { saver.send(method) }.not_to change { BoardAuthor.count }

    post.reload
    expect(post.tagging_authors).to match_array([user, other_user])

    board.reload
    expect(board.coauthors).to be_empty
    expect(board.cameos).to be_empty
  end
end

RSpec.describe Post::Saver do
  let(:user) { create(:user) }

  describe "create" do
    it_behaves_like "post", 'create!'

    let(:post) { build(:post, user: user) }
    let(:params) { ActionController::Parameters.new({ id: post.id }) }

    it "handles post submitted with no authors" do
      create(:user) # non-author
      board_creator = create(:user)
      board = create(:board, creator: board_creator)

      params[:post] = {
        subject: 'a',
        user_id: user.id,
        board_id: board.id,
        unjoined_author_ids: ['']
      }
      saver = Post::Saver.new(post, user: user, params: params)

      time = Time.zone.now - 5.minutes
      Timecop.freeze(time) do
        expect { saver.create! }.to change { PostAuthor.count }.by(1)
      end

      post.reload
      expect(post.tagging_authors).to eq([post.user])
      expect(post.authors).to match_array([user])

      post_author = post.post_authors.first
      expect(post_author.can_owe).to eq(true)
      expect(post_author.joined).to eq(true)
      expect(post_author.joined_at).to be_the_same_time_as(time)
    end

    it "creates new post authors correctly" do
      other_user = create(:user)
      create(:user) # user should not be author
      board_creator = create(:user) # user should not be author
      board = create(:board, creator: board_creator)

      params[:post] = {
        subject: 'a',
        user_id: user.id,
        board_id: board.id,
        unjoined_author_ids: [other_user.id]
      }
      saver = Post::Saver.new(post, user: user, params: params)

      time = Time.zone.now - 5.minutes
      Timecop.freeze(time) do
        expect { saver.create! }.to change { PostAuthor.count }.by(2)
      end

      post.reload
      expect(post.tagging_authors).to match_array([user, other_user])

      post_author = post.author_for(user)
      expect(post_author.can_owe).to eq(true)
      expect(post_author.joined).to eq(true)
      expect(post_author.joined_at).to be_the_same_time_as(time)

      other_post_author = post.author_for(other_user)
      expect(other_post_author.can_owe).to eq(true)
      expect(other_post_author.joined).to eq(false)
      expect(other_post_author.joined_at).to be_nil
    end

    it "generates a flat post" do
      params[:post] = {
        subject: 'subject',
        board_id: create(:board).id,
        privacy: Concealable::REGISTERED,
        content: 'content',
      }
      saver = Post::Saver.new(post, user: user, params: params)
      saver.create!
      post.reload
      expect(post.flat_post).not_to be_nil
    end
  end

  describe "update" do
    it_behaves_like "post", 'update!'

    let(:post) { create(:post, user: user) }
    let(:params) { ActionController::Parameters.new({ id: post.id }) }

    it "correctly updates when adding new authors" do
      other_user = create(:user)

      time = Time.zone.now + 5.minutes
      params[:post] = {
        subject: 'add authors', # TODO this is necessary and therefore a problem
        unjoined_author_ids: [other_user.id]
      }
      saver = Post::Saver.new(post, user: user, params: params)

      Timecop.freeze(time) do
        expect { saver.update! }.to change { PostAuthor.count }.by(1)
      end

      post.reload
      expect(post.tagging_authors).to match_array([user, other_user])
      expect(post.updated_at).to be_the_same_time_as(time)

      # doesn't change joined time or invited status when inviting main user
      main_author = post.post_authors.find_by(user: user)
      expect(main_author.can_owe).to eq(true)
      expect(main_author.joined).to eq(true)
      expect(main_author.joined_at).to be_the_same_time_as(post.created_at)

      # doesn't set joined time but does set invited status when inviting new user
      new_author = post.post_authors.find_by(user: other_user)
      expect(new_author.can_owe).to eq(true)
      expect(new_author.joined).to eq(false)
      expect(new_author.joined_at).to be_nil
    end

    it "correctly updates when removing authors" do
      invited_user = create(:user)
      joined_user = create(:user)

      time = Time.zone.now - 5.minutes
      reply = nil
      Timecop.freeze(time) do
        post.update!(unjoined_authors: [invited_user])
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

      params[:post] = { unjoined_author_ids: [''] }
      saver = Post::Saver.new(post, user: user, params: params)
      expect { saver.update! }.not_to raise_error

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
      params[:post] = {
        setting_ids: [setting1, setting2, setting3].map(&:id),
        content_warning_ids: [warning1, warning2, warning3].map(&:id),
        label_ids: [tag1, tag2, tag3].map(&:id)
      }
      saver = Post::Saver.new(post, user: user, params: params)
      expect { saver.update! }.not_to raise_error

      post.reload
      expect(post.settings).to eq([setting1, setting2, setting3])
      expect(post.content_warnings).to eq([warning1, warning2, warning3])
      expect(post.labels).to eq([tag1, tag2, tag3])
    end

    it "does not allow coauthors to edit post text" do
      skip "Is not currently implemented on saving data"
      coauthor = create(:user)
      post.update!(authors: [user, coauthor], authors_locked: true)
      params[:post] = { content: "newtext" }
      saver = Post::Saver.new(post, user: coauthor, params: params)
      expect { saver.update! }.to raise_error
    end
  end
end
