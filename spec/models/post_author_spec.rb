require "spec_helper"

RSpec.describe PostAuthor do
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
      post_author = create(:post_author, user: user, post: post)

      new_author = build(:post_author, user: user, post: post)
      expect(new_author).not_to be_valid
      expect {
        new_author.save!
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#invite_by!" do
    it "skips update if already invited" do
      skip "broken, TODO"
      old_time = Time.now
      old_user = create(:user)
      author = create(:post_author, invited_at: old_time, invited_by: old_user, can_owe: false)
      expect(
        author.invite_by!(author.post.user)
      ).to eq(false)
      author.reload
      expect(author.can_owe).to eq(false)
      expect(author.invited_at).to be_the_same_time_as(old_time)
      expect(author.invited_by).to eq(old_user)
    end

    it "only sets can_owe if inviting self" do
      author = create(:post_author, can_owe: false)
      expect(
        author.invite_by!(author.user)
      ).to eq(true)
      author.reload
      expect(author.can_owe).to eq(true)
      expect(author.invited_at).to be_nil
      expect(author.invited_by).to be_nil
    end

    it "only sets can_owe if already joined" do
      author = create(:post_author, joined: true, can_owe: false)
      expect(
        author.invite_by!(author.post.user)
      ).to eq(true)
      author.reload
      expect(author.joined).to eq(true)
      expect(author.can_owe).to eq(true)
      expect(author.invited_at).to be_nil
      expect(author.invited_by).to be_nil
    end

    it "succeeds" do
      author = create(:post_author)
      time = Time.now + 1.hour
      Timecop.freeze(time) do
        expect(author.invite_by!(author.post.user)).to eq(true)
      end
      author.reload
      expect(author.joined).to eq(false)
      expect(author.can_owe).to eq(true)
      expect(author.invited_at).to be_the_same_time_as(time)
      expect(author.invited_by).to eq(author.post.user)
    end
  end

  describe "#uninvite!" do
    it "revokes permission even if user has joined post" do
      post_author = create(:post_author, joined: true, can_owe: true, invited_at: Time.now, invited_by: create(:user))
      post_author.uninvite!
      post_author.reload
      expect(post_author.joined).to eq(true)
      expect(post_author.can_owe).to eq(false)
      expect(post_author.invited_at).to be_nil
      expect(post_author.invited_by).to be_nil
    end

    it "destroys object if user has not joined" do
      post_author = create(:post_author, joined: false, can_owe: true, invited_at: Time.now, invited_by: create(:user))
      post_author.uninvite!
      expect(post_author.destroyed?).to eq(true)
      expect(PostAuthor.find_by(id: post_author.id)).to be_nil
    end
  end

  describe "#opt_out_of_owed!" do
    it "removes owedness if user previously could owe" do
      post_author = create(:post_author, can_owe: true)
      post_author.opt_out_of_owed!
      expect(post_author.reload.can_owe).to eq(false)
    end

    it "keeps user opted out if they were previously opted out" do
      post_author = create(:post_author, can_owe: false)
      post_author.opt_out_of_owed!
      expect(post_author.reload.can_owe).to eq(false)
    end
  end
end
