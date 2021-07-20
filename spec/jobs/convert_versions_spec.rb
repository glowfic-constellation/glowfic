require Rails.root.join('script', 'convert_versions.rb').to_s

RSpec.describe "#convert_versions" do # rubocop:disable Rspec/DescribeClass
  before(:each) { Audited.auditing_enabled = true }

  after(:each) { Audited.auditing_enabled = false }

  skip "has tests"

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

    it "excludes audits with version_id set"
  end

  describe "#create_version" do
    it "works with posts"

    it "works with characters"

    it "works with blocks"
  end

  describe "#setup_version" do
    let(:user) { create(:user) }
    let(:post) { Timecop.freeze(Time.zone.now - 1.minute) { create(:post, user: user) } }

    context "with posts" do
      it "works for create audit" do
        Audited.audit_class.as_user(user) { post }
        audit = post.audits.first
        version = setup_version(audit, Post::Version)
        expect(version).to be_kind_of(Post::Version)
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
        character = create(:character, user: user)
        Audited.audit_class.as_user(user) do
          post.update!(subject: 'new subject', description: 'new description', board: new_board, character: character)
        end
        audit = post.audits.last
        version = setup_version(audit, Post::Version)
        expect(version).to be_kind_of(Post::Version)
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
        expect(version).to be_kind_of(Post::Version)
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
      it "works for create audit"
      it "works for update audit"
      it "works for destroy audit"
    end

    context "with characters" do
      it "works"
    end

    context "with blocks" do
      it "works for update audit"
      it "works for destroy audit"
    end
  end
end
