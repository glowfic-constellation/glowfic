RSpec.describe Post::Author do
  describe "validations" do
    it 'succeeds' do
      expect(create(:post_author)).to be_valid
    end

    it 'suceeds with multiple posts and one user' do
      user = create(:user)
      post1 = create(:post)
      post2 = create(:post)
      create(:post_author, user: user, post: post1)
      second = build(:post_author, user: user, post: post2)
      expect(second).to be_valid
      expect {
        second.save!
      }.not_to raise_error
    end

    it 'succeeds with one post and multiple users' do
      user1 = create(:user)
      user2 = create(:user)
      post = create(:post)
      create(:post_author, user: user1, post: post)
      second = build(:post_author, user: user2, post: post)
      expect(second).to be_valid
      expect {
        second.save!
      }.not_to raise_error
    end

    it "should require a user" do
      post_author = build(:post_author, user: nil)
      expect(post_author).not_to be_valid
      post_author.user = create(:user)
      expect(post_author).to be_valid
    end

    it "should require a post" do
      post_author = build(:post_author, post: nil)
      expect(post_author).not_to be_valid
      post_author.post = create(:post)
      expect(post_author).to be_valid
    end

    it "should enforce uniqueness for a specific user and post" do
      user = create(:user)
      post = create(:post)
      create(:post_author, user: user, post: post) # post_author

      new_author = build(:post_author, user: user, post: post)
      expect(new_author).not_to be_valid
      expect {
        new_author.save!
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#shows_drafts?" do
    let(:user) { create(:user) }
    let(:post_author) { create(:post_author, user: user) }

    it "defaults to the user's site-wide setting" do
      expect(post_author.shows_drafts?).to eq(false)
      user.update!(show_drafts_to_coauthors: true)
      expect(post_author.reload.shows_drafts?).to eq(true)
    end

    it "is overridden per post" do
      post_author.update!(show_drafts: true)
      expect(post_author.shows_drafts?).to eq(true)

      user.update!(show_drafts_to_coauthors: true)
      post_author.update!(show_drafts: false)
      expect(post_author.reload.shows_drafts?).to eq(false)
    end
  end

  describe ".showing_drafts" do
    it "finds authors sharing by default or by override, and no others" do
      sharing_user = create(:user, show_drafts_to_coauthors: true)
      private_user = create(:user)

      by_default = create(:post_author, user: sharing_user)
      by_override = create(:post_author, user: private_user, show_drafts: true)
      opted_out = create(:post_author, user: sharing_user, show_drafts: false)
      private_author = create(:post_author, user: private_user)

      results = Post::Author.showing_drafts
      expect(results).to include(by_default, by_override)
      expect(results).not_to include(opted_out, private_author)
    end
  end
end
