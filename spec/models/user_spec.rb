require "spec_helper"

RSpec.describe User do
  describe "password encryption" do
    it "should support nil salt_uuid" do
      user = create(:user)
      user.update(salt_uuid: nil)
      user.update(crypted: user.send(:old_crypted_password, 'test'))
      user.reload
      expect(user.authenticate('test')).to eq(true)
    end

    it "should set and support salt_uuid" do
      user = create(:user, password: 'test')
      expect(user.salt_uuid).not_to be_nil
      expect(user.authenticate('test')).to eq(true)
    end
  end

  it "should be unique by username" do
    user = create(:user, username: 'testuser1')
    new_user = build(:user, username: user.username.upcase)
    expect(new_user).not_to be_valid
  end

  describe "emails" do
    def generate_emailless_user
      user = build(:user, email: '')
      user.send(:encrypt_password)
      user.save!(validate: false)
      user
    end

    it "should be unique by email case-insensitively" do
      user = create(:user, email: 'testuser1@example.com')
      new_user = build(:user, email: user.email.upcase)
      expect(new_user).not_to be_valid
    end

    it "should require emails on new accounts" do
      user = build(:user, email: '')
      expect(user).not_to be_valid
      user.email = 'testuser@example.com'
      expect(user).to be_valid
    end

    it "should allow users with no email to be changed" do
      generate_emailless_user # to have duplicate without email
      user = generate_emailless_user
      user.layout = 'starrydark'
      expect(user).to be_valid
      expect {
        user.save!
      }.not_to raise_error
    end

    it "should allow users with no email to get an email" do
      generate_emailless_user # to have duplicate without email
      user = generate_emailless_user
      user.email = 'testuser@example.com'
      expect(user).to be_valid
      expect {
        user.save!
      }.not_to raise_error
    end
  end
end
