require "spec_helper"

RSpec.describe User do
  describe "password encryption" do
    it "should support nil salt_uuid" do
      user = create(:user)
      user.update_attribute(:salt_uuid, nil)
      user.update_attribute(:crypted, user.send(:old_crypted_password, 'test'))
      user.reload
      expect(user.authenticate('test')).to be_true
    end

    it "should set and support salt_uuid" do
      user = create(:user, password: 'test')
      expect(user.salt_uuid).not_to be_nil
      expect(user.authenticate('test')).to be_true
    end
  end

  it "should be unique by username" do
    user = create(:user, username: 'testuser1')
    new_user = build(:user, username: user.username.upcase)
    expect(new_user).not_to be_valid
  end

  it "should be unique by email" do
    user = create(:user, email: 'testuser1@example.com')
    new_user = build(:user, email: user.email.upcase)
    expect(new_user).not_to be_valid
  end
end
