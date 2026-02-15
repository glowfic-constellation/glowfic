RSpec.describe Bookmark do
  describe "validations" do
    it "requires user" do
      bookmark = Bookmark.new(type: 'reply_bookmark')
      expect(bookmark).not_to be_valid
      expect(bookmark.errors[:user]).to be_present
    end

    it "requires reply" do
      bookmark = Bookmark.new(type: 'reply_bookmark')
      expect(bookmark).not_to be_valid
      expect(bookmark.errors[:reply]).to be_present
    end

    it "requires post" do
      bookmark = Bookmark.new(type: 'reply_bookmark')
      expect(bookmark).not_to be_valid
      expect(bookmark.errors[:post]).to be_present
    end

    it "requires valid type" do
      reply = create(:reply)
      bookmark = Bookmark.new(user: reply.user, reply: reply, post: reply.post, type: 'invalid_type')
      expect(bookmark).not_to be_valid
      expect(bookmark.errors[:type]).to be_present
    end

    it "requires non-nil type" do
      reply = create(:reply)
      bookmark = Bookmark.new(user: reply.user, reply: reply, post: reply.post, type: nil)
      expect(bookmark).not_to be_valid
    end

    it "validates uniqueness of type per user and reply" do
      reply = create(:reply)
      Bookmark.create!(user: reply.user, reply: reply, post: reply.post, type: 'reply_bookmark')
      dup = Bookmark.new(user: reply.user, reply: reply, post: reply.post, type: 'reply_bookmark')
      expect(dup).not_to be_valid
    end

    it "creates a valid bookmark" do
      reply = create(:reply)
      bookmark = Bookmark.new(user: reply.user, reply: reply, post: reply.post, type: 'reply_bookmark')
      expect(bookmark).to be_valid
    end
  end

  describe "#visible_to?" do
    let(:owner) { create(:user) }
    let(:other) { create(:user) }
    let(:reply) { create(:reply) }
    let(:bookmark) { Bookmark.create!(user: owner, reply: reply, post: reply.post, type: 'reply_bookmark') }

    it "returns true for bookmark owner" do
      expect(bookmark.visible_to?(owner)).to be true
    end

    it "returns false when post is not visible" do
      reply.post.update!(privacy: :private)
      expect(bookmark.visible_to?(other)).to be false
    end

    it "returns true when bookmark is public" do
      bookmark.update!(public: true)
      expect(bookmark.visible_to?(other)).to be true
    end

    it "returns true when user has public_bookmarks" do
      owner.update!(public_bookmarks: true)
      expect(bookmark.visible_to?(other)).to be true
    end

    it "returns false for non-owner when bookmark and user bookmarks are private" do
      owner.update!(public_bookmarks: false)
      bookmark.update!(public: false)
      expect(bookmark.visible_to?(other)).to be false
    end
  end
end
