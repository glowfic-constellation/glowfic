require "spec_helper"

RSpec.describe PostView do
  describe "validations" do
    it "requires post" do
      view = build(:post_view, post: nil)
      expect(view).not_to be_valid
      expect(view.save).to eq(false)
    end

    it "requires user" do
      view = build(:post_view, user: nil)
      expect(view).not_to be_valid
      expect(view.save).to eq(false)
    end

    it "works with both user and post" do
      view = build(:post_view)
      user = view.user
      post = view.post
      expect(view).to be_valid
      expect(view.save).to eq(true)
      view.reload
      expect(view.user).to eq(user)
      expect(view.post).to eq(post)
    end

    it "is unique by post and user" do
      view = create(:post_view)
      new_view = build(:post_view, user: view.user, post: view.post)
      expect(new_view).not_to be_valid
      expect(new_view.save).to eq(false)
    end

    it "allows one user to have multiple post views" do
      user = create(:user)
      view = create(:post_view, user: user)
      new_view = build(:post_view, user: user)
      expect(new_view.post).not_to eq(view.post)
      expect(new_view).to be_valid
      expect(new_view.save).to eq(true)
    end

    it "allows one post to have multiple users in post views" do
      post = create(:post)
      view = create(:post_view, post: post)
      new_view = build(:post_view, post: post)
      expect(new_view.user).not_to eq(view.user)
      expect(new_view).to be_valid
      expect(new_view.save).to eq(true)
    end
  end
end
