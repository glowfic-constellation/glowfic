RSpec.describe UserTag do
  it "should be valid" do
    user = create(:user)
    tag = ContentWarning.first || create(:content_warning)
    user_tag = UserTag.new(user: user, tag: tag)
    expect(user_tag).to be_valid
  end

  it "requires a user" do
    tag = ContentWarning.first || create(:content_warning)
    user_tag = UserTag.new(tag: tag)
    expect(user_tag).not_to be_valid
    expect(user_tag.errors[:user]).to be_present
  end

  it "validates uniqueness of user per tag" do
    user = create(:user)
    tag = ContentWarning.first || create(:content_warning)
    UserTag.create!(user: user, tag: tag)
    dup = UserTag.new(user: user, tag: tag)
    expect(dup).not_to be_valid
  end
end
