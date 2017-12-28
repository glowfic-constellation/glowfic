require "spec_helper"

RSpec.describe PostAuthor do
  describe "validations" do
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

    it "should not allow creating twice for the same data" do
      user = create(:user)
      post = create(:post)
      post_author = create(:post_author, user: user, post: post)
      expect{create(:post_author, user: user, post: post)}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
