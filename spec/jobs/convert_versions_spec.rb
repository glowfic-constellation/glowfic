require Rails.root.join('script', 'convert_versions.rb').to_s

RSpec.describe "#convert_versions" do # rubocop:disable Rspec/DescribeClass
  let(:user) { create(:user) }
  let(:mod) { create(:mod_user) }
  let(:post) { create(:post, user: user) }
  let(:character) { create(:character, user: user) }
  let(:reply) { create(:reply, post: post, user: user) }
  let(:block) { create(:block, blocking_user: user) }

  before(:each) { Audited.auditing_enabled = true }

  after(:each) { Audited.auditing_enabled = false }

  it "converts audits" do
    posts = create_list(:post, 10)
    posts.each { |post| create_list(:reply, 3, post: post, with_character: true, with_icon: true) }
    posts = Post.where(id: posts.map(&:id))
    replies = Reply.all
    characters = Character.all
    Audited.audit_class.as_user(mod) do
      characters.each { |char| char.update!(name: char.name + ' updated') }
    end
    blocks = create_list(:block, 10)
    blocks.each { |block| block.update!(hide_me: :posts) }
    count = posts.count + replies.count + characters.count + blocks.count
    expect(Audited::Audit.count).to eq(count)

    convert_versions

    expect(Character::Version.count).to eq(characters.count)
    expect(Post::Version.count).to eq(posts.count)
    expect(Reply::Version.count).to eq(replies.count)
    expect(Block::Version.count).to eq(blocks.count)
  end

  describe "#audits_for" do
    it "finds all post audits" do
      posts = create_list(:post, 5)
      posts.second.update!(description: 'new description')
      posts.last.destroy!
      expect(audits_for('Post').count).to eq(7)
    end

    it "finds all reply audits" do
      replies = create_list(:reply, 5)
      replies.second.update!(content: 'new content')
      replies.last.destroy!
      expect(audits_for('Reply').count).to eq(7)
    end

    it "finds all character audits" do
      characters = create_list(:character, 5)
      Audited.audit_class.as_user(create(:mod_user)) do
        characters.second.update!(description: 'new description')
        characters.last.destroy!
      end
      expect(audits_for('Character').count).to eq(1)
    end

    it "finds all block audits" do
      blocks = create_list(:block, 5)
      blocks.second.update!(hide_me: :posts)
      blocks.last.destroy!
      expect(audits_for('Block').count).to eq(2)
    end

    it "excludes audits with version_id set" do
      posts = create_list(:post, 5)
      create_version(Audited::Audit.second, Post::Version)
      create_version(Audited::Audit.last, Post::Version)
      posts.second.update!(description: 'new description')
      posts.last.destroy!
      create_version(Audited::Audit.last, Post::Version)
      expect(audits_for('Post').count).to eq(4)
    end
  end

  describe "#create_version" do
    it "works with posts" do
      Audited.audit_class.as_user(user) { post }
      audit = post.audits.first
      create_version(audit, Post::Version)
      version = Post::Version.last
      expect(version).to be_persisted
      expect(audit.reload.version_id).to eq(version.id)
    end

    it "works with characters" do
      Audited.audit_class.as_user(mod) { character.update(name: 'new name') }
      audit = character.audits.first
      create_version(audit, Character::Version)
      version = Character::Version.last
      expect(version).to be_persisted
      expect(audit.reload.version_id).to eq(version.id)
    end

    it "works with replies" do
      Audited.audit_class.as_user(user) { reply }
      audit = reply.audits.first
      create_version(audit, Reply::Version)
      version = Reply::Version.last
      expect(version).to be_persisted
      expect(audit.reload.version_id).to eq(version.id)
    end

    it "works with blocks" do
      Audited.audit_class.as_user(user) { block.update(hide_me: :posts) }
      audit = block.audits.first
      create_version(audit, Block::Version)
      version = Block::Version.last
      expect(version).to be_persisted
      expect(audit.reload.version_id).to eq(version.id)
    end
  end

  describe "#setup_version" do
    context "with posts" do
      it "works for create audit" do
        Audited.audit_class.as_user(user) { post }
        audit = post.audits.first
        version = setup_version(audit, Post::Version)
        expect(version).to be_a(Post::Version)
        expect(version.item_id).to eq(post.id)
        expect(version.item_type).to eq('Post')
        expect(version.event).to eq('create')
        expect(version.whodunnit).to eq(user.id)
        changes = {
          authors_locked: [nil, false],
          board_id: [nil, post.board_id],
          content: [nil, post.content],
          description: [nil, ""],
          privacy: [nil, 0],
          status: [nil, 0],
          subject: [nil, post.subject],
          user_id: [nil, post.user_id],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end

      it "works for update audit" do
        old_subject = post.subject
        old_board = post.board
        new_board = create(:board)
        Audited.audit_class.as_user(user) do
          post.update!(subject: 'new subject', description: 'new description', board: new_board, character: character)
        end
        audit = post.audits.last
        version = setup_version(audit, Post::Version)
        expect(version).to be_a(Post::Version)
        expect(version.item_id).to eq(post.id)
        expect(version.item_type).to eq('Post')
        expect(version.event).to eq('update')
        expect(version.whodunnit).to eq(user.id)
        changes = {
          board_id: [old_board.id, new_board.id],
          character_id: [nil, character.id],
          description: ["", post.description],
          subject: [old_subject, post.subject],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end

      it "works for destroy audit" do
        Audited.audit_class.as_user(user) do
          post.destroy!
        end
        audit = post.audits.last
        version = setup_version(audit, Post::Version)
        expect(version).to be_a(Post::Version)
        expect(version.item_id).to eq(post.id)
        expect(version.item_type).to eq('Post')
        expect(version.event).to eq('destroy')
        expect(version.whodunnit).to eq(user.id)
        changes = {
          authors_locked: [false, nil],
          board_id: [post.board_id, nil],
          content: [post.content, nil],
          description: ["", nil],
          privacy: [0, nil],
          status: [0, nil],
          subject: [post.subject, nil],
          user_id: [post.user_id, nil],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end
    end

    context "with replies" do
      it "works for create audit" do
        Audited.audit_class.as_user(user) { reply }
        audit = reply.audits.first
        version = setup_version(audit, Reply::Version)
        expect(version).to be_a(Reply::Version)
        expect(version.item_id).to eq(reply.id)
        expect(version.item_type).to eq('Reply')
        expect(version.event).to eq('create')
        expect(version.whodunnit).to eq(user.id)
        expect(version.post_id).to eq(post.id)
        changes = {
          content: [nil, reply.content],
          post_id: [nil, post.id],
          user_id: [nil, user.id],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end

      it "works for update audit" do
        old_content = reply.content
        Audited.audit_class.as_user(user) do
          reply.update!(content: 'new content', character: character)
        end
        audit = reply.audits.last
        version = setup_version(audit, Reply::Version)
        expect(version).to be_kind_of(Reply::Version)
        expect(version.item_id).to eq(reply.id)
        expect(version.item_type).to eq('Reply')
        expect(version.event).to eq('update')
        expect(version.whodunnit).to eq(user.id)
        expect(version.post_id).to eq(post.id)
        changes = {
          content: [old_content, reply.content],
          character_id: [nil, character.id],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end

      it "works for destroy audit" do
        Audited.audit_class.as_user(user) do
          reply.destroy!
        end
        audit = reply.audits.last
        version = setup_version(audit, Reply::Version)
        expect(version).to be_a(Reply::Version)
        expect(version.item_id).to eq(reply.id)
        expect(version.item_type).to eq('Reply')
        expect(version.event).to eq('destroy')
        expect(version.whodunnit).to eq(user.id)
        expect(version.post_id).to eq(post.id)
        changes = {
          content: [reply.content, nil],
          post_id: [post.id, nil],
          user_id: [user.id, nil],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end
    end

    context "with characters" do
      it "works" do
        old_name = character.name
        template = create(:template, user: user)
        Audited.audit_class.as_user(mod) do
          character.update!(name: 'new name', template: template, screenname: 'test_screen_name')
        end
        audit = character.audits.last
        audit.update!(comment: 'test comment')
        version = setup_version(audit, Character::Version)
        expect(version).to be_a(Character::Version)
        expect(version.item_id).to eq(character.id)
        expect(version.item_type).to eq('Character')
        expect(version.event).to eq('update')
        expect(version.whodunnit).to eq(mod.id)
        changes = {
          name: [old_name, character.name],
          template_id: [nil, template.id],
          screenname: [nil, character.screenname],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to eq(audit.comment)
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end
    end

    context "with blocks" do
      it "works for update audit" do
        Audited.audit_class.as_user(user) do
          block.update!(block_interactions: false, hide_me: :posts, hide_them: :all)
        end
        audit = block.audits.last
        version = setup_version(audit, Block::Version)
        expect(version).to be_a(Block::Version)
        expect(version.item_id).to eq(block.id)
        expect(version.item_type).to eq('Block')
        expect(version.event).to eq('update')
        expect(version.whodunnit).to eq(user.id)
        changes = {
          block_interactions: [true, false],
          hide_me: [0, 1],
          hide_them: [0, 2],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end

      it "works for destroy audit" do
        Audited.audit_class.as_user(user) do
          block.destroy!
        end
        audit = block.audits.last
        version = setup_version(audit, Block::Version)
        expect(version).to be_a(Block::Version)
        expect(version.item_id).to eq(block.id)
        expect(version.item_type).to eq('Block')
        expect(version.event).to eq('destroy')
        expect(version.whodunnit).to eq(user.id)
        changes = {
          block_interactions: [true, nil],
          blocking_user_id: [block.blocking_user_id, nil],
          blocked_user_id: [block.blocked_user_id, nil],
          hide_me: [0, nil],
          hide_them: [0, nil],
        }.transform_keys(&:to_s)
        expect(version.object_changes.keys).to match_array(changes.keys)
        version.object_changes.each do |key, value|
          expect(value).to eq(changes[key])
        end
        expect(version.comment).to be_nil
        expect(version.ip).to eq(audit.remote_address)
        expect(version.request_uuid).to eq(audit.request_uuid)
        expect(version.created_at).to be_the_same_time_as(audit.created_at)
      end
    end
  end
end
