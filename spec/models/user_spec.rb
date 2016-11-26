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
end
